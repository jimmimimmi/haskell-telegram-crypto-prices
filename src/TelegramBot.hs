module TelegramBot where

import Control.Applicative ((<|>))
import Control.Monad.IO.Class (liftIO)
import Data.Maybe
import Data.Text
import Data.Time (getCurrentTime)
import Database.Persist.Class.PersistEntity (entityVal)
import Db.Query
import Db.Schema
import PriceProvider
import Telegram.Bot.API as Telegram
import Telegram.Bot.Simple
import Telegram.Bot.Simple.UpdateParser

data ChatState = InitSate deriving (Show, Eq)

newtype ChatModel = ChatModel ChatState deriving (Show, Eq)

data Action
  = NoAction
  | TextAction Int (Maybe Text) Int Bool Text
  deriving (Show, Read)

--provide the token for your bot here
botToken :: Token
botToken = Token "5429988748:AAEWEk42ca-jJ7V5xpX_RmIKyHRzN9kQFm4"

botStartup :: IO ()
botStartup = do
  env <- defaultTelegramClientEnv botToken
  startBot_ (conversationBot updateChatId botApp) env

emptyChatModel :: ChatModel
emptyChatModel = ChatModel InitSate

botApp :: BotApp ChatModel Action
botApp =
  BotApp
    { botInitialModel = emptyChatModel,
      botAction = parseAction,
      botHandler = handleAction,
      botJobs = []
    }

parseAction :: Update -> ChatModel -> Maybe Action
parseAction update _ = do
  msg <- updateMessage update
  usr <- messageFrom msg
  let Telegram.UserId usrId = Telegram.userId usr
  let Telegram.MessageId msgId = Telegram.messageMessageId msg
  let usrIdInt = fromIntegral usrId
  let msgIdInt = fromIntegral msgId
  let usrName = Telegram.userUsername usr
  let parser =
        TextAction usrIdInt usrName msgIdInt True <$> command (pack "history")
          <|> TextAction usrIdInt usrName msgIdInt False <$> plainText
  parseUpdate parser update

greeting :: Maybe Text -> Text
greeting = fromMaybe "Anonym"

saveNewUser :: Int -> Maybe Text -> IO (Maybe (Key Db.Schema.User))
saveNewUser uid userName =
  do
    maybeUser <- getUserById uid
    now <- getCurrentTime
    case maybeUser of
      Nothing -> Just <$> createUser (Db.Schema.User uid userName now)
      Just _ -> pure Nothing

saveHistoryPrice :: Int -> Int -> TickerPrice -> IO (Key Price)
saveHistoryPrice uid priceId tickerPrice =
  do
    now <- getCurrentTime
    let name = (toUpper . pack . ticker) tickerPrice
    let value = (pack . price) tickerPrice
    insertHistoryPrice $ Price priceId (UserKey uid) name value now

printPrice :: Price -> Text
printPrice e = mconcat [priceTicker e, ": ", priceValue e, "(", pack . show $ priceSent e, ")"]

processUserRequest :: Int -> Int -> Bool -> Text -> BotM ()
processUserRequest uid msgId isHistoryCmd txt =
  if isHistoryCmd
    then do
      entities <- liftIO $ loadHistory uid
      replyToUser $ intercalate ", " $ printPrice . entityVal <$> entities
    else do
      priceResponse <- liftIO $ getPrice txt
      case priceResponse of
        Right tickerPrice ->
          do
            _ <- liftIO $ saveHistoryPrice uid msgId tickerPrice
            replyToUser $ pack $ mconcat [ticker tickerPrice, ": ", price tickerPrice]
        Left _ -> replyToUser $ mconcat ["Couldn't get the price for the ticker: ", txt]

handleAction :: Action -> ChatModel -> Eff Action ChatModel
handleAction action model =
  case action of
    NoAction -> pure model
    TextAction uid userName msgId isHistoryCmd txt ->
      model <# do
        saved <- liftIO $ saveNewUser uid userName
        case saved of
          Just _ -> replyToUser $ mconcat ["Welcome, ", greeting userName, ". Type crypto tickers to get prices. E.g.: bnbbtc, ethbtc"]
          Nothing -> do
            _ <- replyToUser $ mconcat ["Hi again ", greeting userName, ". Processing your request"]
            processUserRequest uid msgId isHistoryCmd txt
        pure NoAction

replyToUser :: Text -> BotM ()
replyToUser = reply . toReplyMessage
