{-# LANGUAGE RecordWildCards #-}

module Lib
  ( someFunc
  ) where

import           System.Environment (getArgs)

data Face = FaceX | FaceY | FaceNX | FaceNY
  deriving (Show)

data Action = TurnLeft | TurnRight | Forward | Place | Up | Down
  deriving (Show)

data PlaceOpt = NoPlace | PlaceDown
  deriving (Show)

data ParseOpt = XYZ | XZY
  deriving (Show)

data Robot = Robot
  { robotX        :: Int
  , robotY        :: Int
  , robotZ        :: Int
  , robotFace     :: Face
  , robotActions  :: [Action]
  , robotPlaceOpt :: PlaceOpt
  } deriving (Show)

data Point = Point
  { pointX :: Int
  , pointY :: Int
  , pointZ :: Int
  } deriving (Show)

zeroPoint :: Point
zeroPoint = Point 0 200 200

newRobot :: PlaceOpt -> Point -> Robot
newRobot opt Point {..} = Robot pointX pointY pointZ FaceY [] opt

type Layer = [Point]

turnLeft :: Robot -> Robot
turnLeft r = r
  { robotFace    = go (robotFace r)
  , robotActions = robotActions r ++ [TurnLeft]
  }
  where go :: Face -> Face
        go FaceX  = FaceY
        go FaceY  = FaceNX
        go FaceNX = FaceNY
        go FaceNY = FaceX

turnRight :: Robot -> Robot
turnRight r = r
  { robotFace    = go (robotFace r)
  , robotActions = robotActions r ++ [TurnRight]
  }
  where go :: Face -> Face
        go FaceX  = FaceNY
        go FaceNY = FaceNX
        go FaceNX = FaceY
        go FaceY  = FaceX

forward :: Robot -> Robot
forward r = (go $ robotFace r)
  { robotActions = robotActions r ++ [Forward]
  }
  where go :: Face -> Robot
        go FaceX  = r { robotX = robotX r + 1 }
        go FaceY  = r { robotY = robotY r + 1 }
        go FaceNX = r { robotX = robotX r - 1 }
        go FaceNY = r { robotY = robotY r - 1 }

place :: Robot -> Robot
place r = go (robotPlaceOpt r)
  where go :: PlaceOpt -> Robot
        go NoPlace = r
        go PlaceDown = r
          { robotActions = robotActions r ++ [Place]
          }

up :: Robot -> Robot
up r = r
  { robotActions = robotActions r ++ [Up]
  , robotZ = robotZ r + 1
  }

down :: Robot -> Robot
down r = r
  { robotActions = robotActions r ++ [Down]
  , robotZ = robotZ r - 1
  }

turnFace :: Face -> Robot -> Robot
turnFace f r = go (robotFace r) f r
  where go :: Face -> Face -> Robot -> Robot
        go FaceX FaceX   = id
        go FaceX FaceY   = turnLeft
        go FaceX FaceNX  = turnLeft . turnLeft
        go FaceX FaceNY  = turnRight

        go FaceY FaceX   = turnRight
        go FaceY FaceY   = id
        go FaceY FaceNX  = turnLeft
        go FaceY FaceNY  = turnRight . turnRight

        go FaceNX FaceX  = turnLeft . turnLeft
        go FaceNX FaceY  = turnRight
        go FaceNX FaceNX = id
        go FaceNX FaceNY = turnLeft

        go FaceNY FaceX  = turnLeft
        go FaceNY FaceY  = turnLeft . turnLeft
        go FaceNY FaceNX = turnRight
        go FaceNY FaceNY = id

moveX :: Int -> Robot -> Robot
moveX x r | x > robotX r = moveX x $ forward $ turnFace FaceX r
          | x < robotX r = moveX x $ forward $ turnFace FaceNX r
          | otherwise = r

moveY :: Int -> Robot -> Robot
moveY y r | y > robotY r = moveY y $ forward $ turnFace FaceY r
          | y < robotY r = moveY y $ forward $ turnFace FaceNY r
          | otherwise = r

moveZ :: Int -> Robot -> Robot
moveZ z r | z > robotZ r = moveZ z $ up r
          | z < robotZ r = moveZ z $ down r
          | otherwise = r

move :: Point -> Robot -> Robot
move Point {..} = moveZ pointZ . moveY pointY . moveX pointX

distance :: Point -> Robot -> Int
distance Point {..} Robot {..} = abs (pointX - robotX) + abs (pointY - robotY) + abs (pointZ - robotZ)

findNearPoint :: [Point] -> Robot -> Maybe (Point, [Point])
findNearPoint [] _     = Nothing
findNearPoint [x] _    = Just (x, [])
findNearPoint (x:xs) r = do
  (p, ps) <- findNearPoint xs r
  if distance p r < distance x r then return (p, x:ps)
                                 else return (x, p:ps)

printLayer :: [Point] -> Robot -> Robot
printLayer xs r =
  case findNearPoint xs r of
    Nothing      -> r
    Just (p, ps) -> printLayer ps . place $ move p r

printLayers :: [Layer] -> Robot -> Robot
printLayers []     = id
printLayers (x:xs) = printLayers xs . printLayer x

ignoreLine :: String -> String
ignoreLine []         = []
ignoreLine ('\n': xs) = xs
ignoreLine (_:xs)     = ignoreLine xs

-- parseLayer opt xs x y z l
parseLayer :: ParseOpt -> String -> Int -> Int -> Int -> Layer -> (Layer, String)
parseLayer _   [] _ _ _ ps             = (ps, [])
parseLayer opt ('0':xs) x y z ps       = parseLayer opt xs (x+1) y z ps
parseLayer opt ('1':xs) x y z ps       = parseLayer opt xs (x+1) y z (Point x y z : ps)
parseLayer _   ('\n':'\n':xs) _ _ _ ps = (ps, xs)
parseLayer XYZ ('\n':xs) _ y z ps      = parseLayer XYZ xs (pointX zeroPoint) (y - 1) z ps
parseLayer XZY ('\n':xs) _ y z ps      = parseLayer XZY xs (pointX zeroPoint) y (z - 1) ps
parseLayer opt ('#':xs) x y z ps       = parseLayer opt (ignoreLine xs) x y z ps
parseLayer opt (_:xs) x y z ps         = parseLayer opt xs x y z ps


parseLayers :: ParseOpt -> Int -> String -> [Layer]
parseLayers _ _ [] = []
parseLayers XYZ z xs =
  case parseLayer XYZ xs (pointX zeroPoint) (pointY zeroPoint) z [] of
    (layer, ps) -> layer : parseLayers XYZ (z + 1) ps

parseLayers XZY y xs =
  case parseLayer XZY xs (pointX zeroPoint) y (pointZ zeroPoint) [] of
    (layer, ps) -> layer : parseLayers XZY (y + 1) ps

getMinY :: [Layer] -> Int
getMinY [] = pointY zeroPoint
getMinY (x:xs) = min (go x) (getMinY xs)
  where go :: Layer -> Int
        go = foldr (min . pointY) (pointY zeroPoint)

getMinZ :: [Layer] -> Int
getMinZ [] = pointZ zeroPoint
getMinZ (x:xs) = min (go x) (getMinZ xs)
  where go :: Layer -> Int
        go = foldr (min . pointZ) (pointZ zeroPoint)

printAction :: Action -> Char
printAction TurnLeft  = 'L'
printAction TurnRight = 'R'
printAction Forward   = 'F'
printAction Place     = 'P'
printAction Up        = 'U'
printAction Down      = 'D'

printActions :: [Action] -> Int -> String
printActions [] _     = []
printActions (x:xs) i | i > 39 = printAction x : '\n' : printActions xs 0
                      | otherwise = printAction x : printActions xs (i + 1)

data Options = Options
  { placeOpt  :: PlaceOpt
  , parseOpt  :: ParseOpt
  , layerFile :: FilePath
  , showHelp  :: Bool
  } deriving Show

defaultOptions = Options
  { placeOpt  = PlaceDown
  , parseOpt  = XYZ
  , layerFile = "layers.txt"
  , showHelp  = False
  }

parseOptions :: Options -> [String] -> Options
parseOptions opt []                  = opt
parseOptions opt ("-h":xs)           = parseOptions opt {showHelp = True} xs
parseOptions opt ("--help":xs)       = parseOptions opt {showHelp = True} xs
parseOptions opt ("--xyz":xs)        = parseOptions opt {parseOpt = XYZ} xs
parseOptions opt ("--xzy":xs)        = parseOptions opt {parseOpt = XZY} xs
parseOptions opt ("--no-place":xs)   = parseOptions opt {placeOpt = NoPlace} xs
parseOptions opt ("--place-down":xs) = parseOptions opt {placeOpt = PlaceDown} xs
parseOptions opt (x:xs)              = parseOptions opt {layerFile = x} xs

runPrint :: Options -> IO ()
runPrint Options {..} = do
  layers <- parseLayers parseOpt 0 <$> readFile layerFile
  let initPoint = zeroPoint { pointY = getMinY layers, pointZ = getMinZ layers }
  putStrLn
    $ flip printActions 0
    . robotActions
    . turnFace FaceY
    . move initPoint
    . move initPoint {pointX = pointX initPoint - 1}
    . printLayers layers
    $ newRobot placeOpt initPoint

printHelp :: IO ()
printHelp = putStrLn "robot-print [--xyz|--xzy] [--no-place|--place-down] [-h|--help] layers.txt"

someFunc :: IO ()
someFunc =  do
  opt <- parseOptions defaultOptions <$> getArgs

  if showHelp opt then printHelp else runPrint opt
