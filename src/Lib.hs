{-# LANGUAGE RecordWildCards #-}

module Lib
  ( someFunc
  ) where

data Face = FaceX | FaceY | FaceNX | FaceNY
  deriving (Show)
data Action = TurnLeft | TurnRight | Forward | Place | Up
  deriving (Show)

data Robot = Robot
  { robotX       :: Int
  , robotY       :: Int
  , robotFace    :: Face
  , robotActions :: [Action]
  } deriving (Show)

data Point = Point
  { pointX :: Int
  , pointY :: Int
  } deriving (Show)

type Layer = [Point]

turnLeft :: Robot -> Robot
turnLeft r = r
  { robotFace = go (robotFace r)
  , robotActions = robotActions r ++ [TurnLeft]
  }
  where go :: Face -> Face
        go FaceX  = FaceY
        go FaceY  = FaceNX
        go FaceNX = FaceNY
        go FaceNY = FaceX

turnRight :: Robot -> Robot
turnRight r = r
  { robotFace = go (robotFace r)
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
place r = r
  { robotActions = robotActions r ++ [Place]
  }

up :: Robot -> Robot
up r = r
  { robotActions = robotActions r ++ [Up]
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

move :: Point -> Robot -> Robot
move Point {..} = moveY pointY . moveX pointX

distance :: Point -> Robot -> Int
distance Point {..} Robot {..} = (pointX - robotX) * (pointX - robotX) + (pointY - robotY) * (pointY - robotY)

findNearPoint :: [Point] -> Robot -> Maybe (Point, [Point])
findNearPoint [] _     = Nothing
findNearPoint [x] _    = Just (x, [])
findNearPoint (x:xs) r = do
  (p, ps) <- findNearPoint xs r
  if distance p r < distance x r then return $ (p, x:ps)
                                 else return $ (x, p:ps)

printLayer :: [Point] -> Robot -> Robot
printLayer xs r =
  case findNearPoint xs r of
    Nothing      -> r
    Just (p, ps) -> printLayer ps . place $ move p r

layer :: Layer
layer =
  [ Point 1 1
  , Point 2 1
  , Point 3 1
  , Point 1 2
  , Point 1 3
  ]

robot :: Robot
robot = Robot 0 0 FaceX []

someFunc :: IO ()
someFunc =  do
  print $ printLayer layer robot
