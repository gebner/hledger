{-| 

Print a histogram report.

-}

module HistogramCommand
where
import Prelude hiding (putStr)
import qualified Data.Map as Map
import Data.Map ((!))
import Ledger
import Options
import System.IO.UTF8


barchar = '*'

-- | Print a histogram of some statistic per reporting interval, such as
-- number of transactions per day.
histogram :: [Opt] -> [String] -> Ledger -> IO ()
histogram opts args l =
  mapM_ (printDayWith countBar) daytxns
    where
      i = intervalFromOpts opts
      interval | i == NoInterval = Daily
               | otherwise = i
      fullspan = rawLedgerDateSpan $ rawledger l
      days = filter (DateSpan Nothing Nothing /=) $ splitSpan interval fullspan
      daytxns = [(s, filter (isTransactionInDateSpan s) ts) | s <- days]
      -- same as RegisterCommand
      ts = sortBy (comparing tdate) $ filterempties $ filter matchapats $ filterdepth $ ledgerTransactions l
      filterempties
          | Empty `elem` opts = id
          | otherwise = filter (not . isZeroMixedAmount . tamount)
      matchapats t = matchpats apats $ taccount t
      (apats,_) = parsePatternArgs args
      filterdepth | interval == NoInterval = filter (\t -> (accountNameLevel $ taccount t) <= depth)
                  | otherwise = id
      depth = depthFromOpts opts

printDayWith f (DateSpan b _, ts) = putStrLn $ printf "%s %s" (show $ fromJust b) (f ts)

countBar ts = replicate (length ts) barchar

total ts = show $ sumTransactions ts

-- totalBar ts = replicate (sumTransactions ts) barchar
