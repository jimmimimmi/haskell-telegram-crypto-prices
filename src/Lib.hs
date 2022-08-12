module Lib
  ( bootstrap,
  )
where

import Db.Query
import TelegramBot

bootstrap :: IO ()
bootstrap = prepareDb >> botStartup
