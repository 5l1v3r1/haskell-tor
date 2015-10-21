module Tor.Options(
         -- * Options for running Tor
         TorOptions(..),         defaultTorOptions
       , TorEntranceOptions(..), defaultTorEntranceOptions
       , TorRelayOptions(..),    defaultTorRelayOptions
       , TorExitOptions(..),     defaultTorExitOptions
       , ExitRule(..), AddrSpec(..), PortSpec(..)
         -- * Handy utilities
       , makeLogger
       )
 where

import Data.Hourglass
import Data.Hourglass.Now
import Data.Word
import Tor.RouterDesc

-- |How the node should be set up during initialization. For each of these
-- items, 'Nothing' means that the node will not operate in that capacity, while
-- Just of the option type will initialize that system with those options.
--
-- Note that while we will do our best to make it work, it doesn't make a whole
-- lot of sense to be an Exit node and not be a Relay node.
data TorOptions = TorOptions {
       torLog             :: String -> IO ()
     , torEntranceOptions :: Maybe TorEntranceOptions
     , torRelayOptions    :: Maybe TorRelayOptions
     , torExitOptions     :: Maybe TorExitOptions
     }

-- |A reasonable default set of options for a Tor node. Sets the node up as an
-- entrance and relay node with their standard options, and logging output
-- printed to stdout.
defaultTorOptions :: TorOptions
defaultTorOptions = TorOptions {
    torLog             = makeLogger putStrLn
  , torEntranceOptions = Just defaultTorEntranceOptions
  , torRelayOptions    = Just defaultTorRelayOptions
  , torExitOptions     = Nothing
  }

data TorEntranceOptions = TorEntranceOptions {
       -- |The number of intermediate hops to use between this node and
       -- the exit node. To be clear, created circuits will have an entrance
       -- node, this number of nodes, and then the exit node.
       torInternalCircuitLength :: Int
       -- |The maximum number of circuits to keep open. If you create more than
       -- this many connections, some circuits will be re-used. This may or may
       -- not be a problem for you.
     , torMaxCircuits :: Int
       -- |The maximum number of direct connections to keep open. Note that it
       -- is perfectly possible for this number to be less than torMaxCircuits;
       -- in that case, one or more circuits will share a first hop. On the
       -- other hand, setting this number to more than torMaxCircuits means that
       -- you will always be capable of using more connections than you will
       -- actually use.
     , torMaxConnections :: Int
     }

-- |A reasonable set of entrance options. The internal circuit length is set to
-- 6, and both max circuits and connections are set to 3.
defaultTorEntranceOptions :: TorEntranceOptions
defaultTorEntranceOptions  = TorEntranceOptions {
    torInternalCircuitLength = 6
  , torMaxCircuits           = 3
  , torMaxConnections        = 3
  }

data TorRelayOptions = TorRelayOptions {
      -- |The port to listen on. By default, this is 9374, but there are
      -- compelling reasons to have it be some other wel-known port, like
      -- 80.
      torOnionPort :: Word16
      -- |The nickname for this node. This is completely optional, but can
      -- be helpful in finding yourself in node lists.
    , torNickname  :: String
      -- |A contact email address. If not provided, we will either provide
      -- no email address or just include a junk address.
    , torContact   :: Maybe String
    }

-- |A reasonable set of relay options. The onion port is set to 9374, the
-- nickname is set to "", and no contact information is provided.
defaultTorRelayOptions :: TorRelayOptions
defaultTorRelayOptions  = TorRelayOptions {
    torOnionPort = 9374
  , torNickname  = ""
  , torContact   = Nothing
  }

data TorExitOptions = TorExitOptions {
      -- |The rules for allowing or rejecting traffic leaving this node.
      torExitRules :: [ExitRule]
    }

-- |A reasonable default exit node options. This allows all outgoing
-- traffic to ports 22 (SSH), 80 (HTTP), 443 (HTTPS), 465 (SMTPS), and
-- 993 (IMAPS).
defaultTorExitOptions :: TorExitOptions
defaultTorExitOptions  = TorExitOptions {
    torExitRules = map (\ p -> ExitRuleAccept AddrSpecAll (PortSpecSingle p))
                       [22, 80, 443, 465, 993]
  }

-- -----------------------------------------------------------------------------

-- |If you like the output format of the default log function, but want to
-- send it to your own output stream, this is the function for you! This
-- function takes an outgoing logger and a string to log, and adds a nicely-
-- formatted and easily-sortable timestamp to the front of it.
--
-- NOTE: The default value for the logger is (makeLogger putStrLn).
makeLogger :: (String -> IO ()) -> String -> IO ()
makeLogger out msg =
  do now <- getCurrentTime
     out (timePrint timeFormat now ++ msg)
 where
   timeFormat = [Format_Text '[', Format_Year4, Format_Text '-', Format_Month2,
                 Format_Text '-', Format_Day2, Format_Text ' ', Format_Hour,
                 Format_Text ':', Format_Minute, Format_Text ']',
                 Format_Text ' ']


