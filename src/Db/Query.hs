module Db.Query where

import Control.Monad.Logger
import Control.Monad.Trans.Reader
import Database.Persist.Postgresql
import Db.Schema

dbConn :: ConnectionString
dbConn = "host=localhost port=5432 user=sasha dbname=sasha password=sasha"

prepareDb :: IO ()
prepareDb = runStdoutLoggingT . withPostgresqlPool dbConn 1 . runSqlPool $ doMigration

getUserById :: Int -> IO (Maybe User)
getUserById uid = do
  runStdoutLoggingT $ withPostgresqlConn dbConn $ runReaderT action
  where
    action :: SqlPersistT (LoggingT IO) (Maybe User)
    action = get $ UserKey (fromIntegral uid)

loadHistory :: Int -> IO [Entity Price]
loadHistory uid = do
  runStdoutLoggingT $ withPostgresqlConn dbConn $ runReaderT action
  where
    action :: SqlPersistT (LoggingT IO) [Entity Price]
    action = selectList [PriceUserId ==. UserKey (fromIntegral uid)] [Desc PricePriceId, LimitTo 10]

createUser :: User -> IO (Key User)
createUser user = do
  runStdoutLoggingT $ withPostgresqlConn dbConn $ runReaderT action
  where
    action :: SqlPersistT (LoggingT IO) (Key User)
    action = insert user

insertHistoryPrice :: Price -> IO (Key Price)
insertHistoryPrice msg = do
  runStdoutLoggingT $ withPostgresqlConn dbConn $ runReaderT action
  where
    action :: SqlPersistT (LoggingT IO) (Key Price)
    action = insert msg
