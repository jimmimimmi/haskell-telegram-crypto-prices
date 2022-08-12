{-# LANGUAGE ExistentialQuantification  #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}

module Db.Schema where

import           Control.Monad.IO.Class
import           Data.Text
import           Data.Time
import           Database.Persist.Postgresql
import           Database.Persist.TH

share
  [mkPersist sqlSettings, mkMigrate "migrateAll"]
  [persistLowerCase|
      User
        userId Int
        username Text Maybe
        created UTCTime default=now()

        Primary userId
        deriving Show
      Price
        priceId Int
        userId UserId
        ticker Text
        value Text
        sent UTCTime default=now()

        UniqueMsgUser priceId userId

    |]

doMigration :: MonadIO m => SqlPersistT m ()
doMigration = runMigration migrateAll
