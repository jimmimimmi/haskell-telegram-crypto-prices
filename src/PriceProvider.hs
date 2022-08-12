module PriceProvider where

import Data.Aeson
import Data.Text
import Network.HTTP.Simple

data TickerPrice = TickerPrice
  { ticker :: String,
    price :: String
  }

instance FromJSON TickerPrice where
  parseJSON (Object v) = do
    s <- v .: "symbol"
    p <- v .: "lastPrice"
    return TickerPrice {ticker = s, price = p}

buildUri :: Text -> String
buildUri t = mconcat ["https://api2.binance.com/api/v3/ticker/24hr?symbol=", (unpack . toUpper) t]

getPrice :: Text -> IO (Either String TickerPrice)
getPrice symbol = do
  request <- parseRequest $ buildUri symbol
  response <- httpJSONEither request
  let maybePrice = case getResponseBody response of
        Right (TickerPrice t p) -> Right $ TickerPrice t p
        Left er -> Left $ show er
  return maybePrice
