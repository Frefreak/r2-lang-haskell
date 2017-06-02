{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE OverloadedStrings #-}
module R2 where

import Foreign.Ptr
import Foreign.C.String
import Control.Concurrent.MVar
import System.IO.Unsafe
import Control.Monad

foreign import ccall "r_core.h r_core_cmd_str" _cmd_str
    :: Ptr RCore -> CString -> IO CString

data RCore

{-# NOINLINE core #-}
core :: MVar (Ptr RCore)
core = unsafePerformIO newEmptyMVar


dangerousInit :: Int -> IO ()
dangerousInit n = do
    let rcore = intPtrToPtr (fromIntegral n)
    _ <- tryTakeMVar core
    putMVar core rcore

cmd :: String -> IO String
cmd s = do
    cs <- newCString s
    co <- readMVar core
    rs <- _cmd_str co cs
    peekCString rs

pcmd :: String -> IO ()
pcmd = cmd >=> putStrLn
