{-# LANGUAGE ForeignFunctionInterface #-}

module Plugin where

foreign export ccall "test_func" testFunc :: IO ()

testFunc :: IO ()
testFunc = writeFile "./temp.txt" $ show [1..10]
