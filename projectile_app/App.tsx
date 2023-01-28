import React, { useState } from "react";
import { View, Dimensions } from "react-native";
import { Gesture, GestureDetector, GestureHandlerRootView } from "react-native-gesture-handler";
import { Canvas, Circle, Line, Path, vec, Vertices} from "@shopify/react-native-skia";

// Define line and ball objects
interface ILine {
  startX: number;
  startY: number;
  endX: number;
  endY: number;
  lineColor: string;
}
interface IBall {
  ballX: number;
  ballY: number;
  ballRadius: number;
  ballColor: string;
  style: string;
}

const distTwoPoints = (x1: number, y1: number, x2: number, y2: number ) => {
  return Math.sqrt((x1 - x2)**2 + (y1 - y2)**2);
};

const launchVelCalc = (
  distToLaunch: number, 
  maxDistToLaunch: number, 
  maxVelocity: number
) => {
  // Launch velocity ~ (distance to launch)/(max allowed distance to launch)
  const distRatio = distToLaunch / maxDistToLaunch;
  const maxVelocityFloat = maxVelocity * distRatio;
  // Convert to integer for sending to Cairo contract
  return Math.round(maxVelocityFloat);
};

const launchAngleDegCalc = (
  finalX: number, 
  finalY: number, 
  launchX: number, 
  launchY: number, 
  distToLaunch: number
) => {
  // Argument for arccos
  const argument = (finalX - launchX)/distToLaunch;
  // Need to define this outside if block below
  let launchAngleDegFloat;

  // Angle is found using device coordinate system (= left-handed system 
  // with origin at upper left of screen, with +x right, +y down).
  // To switch coordinate system (to right-handed with +x right, +y up)
  // and to make launch angle opposite direction ball was pulled, 
  // use extra negative sign, and/or add/subtract 180.
  //
  // First test if in 1st/2nd quadrant, or 3rd/4th quadrant
  if (finalY >= launchY) {
    // If in 1st/2nd quadrant
    launchAngleDegFloat = -Math.acos(argument)*180/Math.PI + 180;
  } else {
    // If in 3rd/4th quadrant
    launchAngleDegFloat = Math.acos(argument)*180/Math.PI - 180;
  }
  // Convert to integer for sending to Cairo contract
  return Math.round(launchAngleDegFloat);
};


export default function App() {    
  // Get dimensions of device screen
  const { width, height } = Dimensions.get("window");
  // Note: orientation is set to landscape in app.json

  // Set initial position of the ball and the starting point of the line to be drawn
  // This is also the position of the ball when launched
  const launchX = 0.2 * width;
  const launchY = 0.6 * height;
  // Set max distance allowed from initial position, in order to begin gesture
  const maxDistBeginGesture = 40;
  // Set max distance ball/line can be pulled from launch position
  const maxDistToLaunch = 0.5 * Math.min(width, height);
  // Set max launch velocity magnitude, corresponding to max pull from launch position
  const maxVelocity = 100;
  // For ball
  const ballRadius = 10;
  const ballColor = "green";
  // For line
  const strokeWidth = 3;
  const lineColor = "black";

  // Use state to initialize and store line and ball data
  const [line, setLine] = useState<ILine | null>(null);
  const [ball, setBall] = useState<IBall>({
    ballX: launchX,
    ballY: launchY,
    ballRadius: ballRadius,
    ballColor: ballColor,
    style: "fill"
  });
  // Use state to initialize and store final x and y positions of ball before launch
  const [finalX, setFinalX] = useState<number>(launchX);
  const [finalY, setFinalY] = useState<number>(launchY);

  const pan = Gesture.Pan()
    // This modifier allows callbacks inside Gesture to run on JS thread, not UI thread 
    .runOnJS(true)

    .onStart((current) => {
      const distToLaunch = distTwoPoints(
        current.x, current.y, launchX, launchY
      );
      // If current distance is within the maximum distance allowed to begin gesture,
      // and there is no line yet...
      if (distToLaunch <= maxDistBeginGesture && !line) {
        setLine({
          startX: current.x,
          startY: current.y,
          endX: launchX,
          endY: launchY,
          lineColor: lineColor,
        });
        setBall({
          ...ball,
          ballX: current.x,
          ballY: current.y,
        });
        setFinalX(current.x);
        setFinalY(current.y);
        console.log('current.x =',current.x);
        console.log('current.y =',current.y);

        // Because distToLaunch <= maxDistBeginGesture, 
        // can assume distToLaunch < maxDistToLaunch, so no need to test here

        // Candidate launch velocity and angle, used to draw partial projectile line
        const candLaunchVel = launchVelCalc(
          distToLaunch, maxDistToLaunch, maxVelocity
        );
        const candLaunchAngleDeg = launchAngleDegCalc(
          finalX, finalY, launchX, launchY, distToLaunch
        );
        console.log('candLaunchVel =', candLaunchVel);
        console.log('candLaunchAngleDeg =',candLaunchAngleDeg);
      }
    })

    .onUpdate((current) => {
      if (line) {
        const distToLaunch = distTwoPoints(
          current.x, current.y, launchX, launchY
        );
        // If current distance is within the maximum distance allowed 
        // away from launch position...
        if (distToLaunch <= maxDistToLaunch) {
          setLine({
            ...line,
            startX: current.x,
            startY: current.y,
          });
          setBall({
            ...ball,
            ballX: current.x,
            ballY: current.y,
          });
          setFinalX(current.x);
          setFinalY(current.y);
          console.log('current.x = ',current.x);
          console.log('current.y = ',current.y);
        } else {
          // Otherwise adjust x and y values so that ball is within 
          // max allowed distance. 
          // Line stops here, but points to current position of gesture
          const ratio = maxDistToLaunch / distToLaunch;
          const adjustedCurrentX = launchX + ratio * (current.x - launchX);
          const adjustedCurrentY = launchY + ratio * (current.y - launchY);
          setLine({
            ...line,
            startX: adjustedCurrentX,
            startY: adjustedCurrentY,
          });
          setBall({
            ...ball,
            ballX: adjustedCurrentX,
            ballY: adjustedCurrentY,
          });
          setFinalX(adjustedCurrentX);
          setFinalY(adjustedCurrentY);
          console.log('current.x =', current.x);
          console.log('current.y =', current.y);
          console.log('adjustedCurrentX =', adjustedCurrentX);
          console.log('adjustedCurrentY =', adjustedCurrentY);
        }
          // Candidate distance to launch position
          const candDistToLaunch = distTwoPoints(
            finalX, finalY, launchX, launchY
          );
          // Candidate launch velocity and angle, 
          // used to draw partial projectile path
          const candLaunchVel = launchVelCalc(
            candDistToLaunch, maxDistToLaunch, maxVelocity
          );
          const candLaunchAngleDeg = launchAngleDegCalc(
            finalX, finalY, launchX, launchY, candDistToLaunch
          );
          console.log('candLaunchVel =', candLaunchVel);
          console.log('candLaunchAngleDeg =',candLaunchAngleDeg);
      }
    })

    .onEnd(() => {
      console.log('finalX =', finalX);
      console.log('finalY =', finalY);
      
      const finalDistToLaunch = distTwoPoints(
        finalX, finalY, launchX, launchY
      );
      
      const launchVelocity = launchVelCalc(
        finalDistToLaunch, maxDistToLaunch, maxVelocity
      );
      console.log('launchVelocity =', launchVelocity);

      const launchAngleDeg = launchAngleDegCalc(
        finalX, finalY, launchX, launchY, finalDistToLaunch
      );
      console.log('launchAngleDeg =', launchAngleDeg);

      // Reset line, ball, and final values
      setLine(null);
      setBall({
        ...ball,
        ballX: launchX,
        ballY: launchY,
      });
      setFinalX(launchX);
      setFinalY(launchY);
    })

    // Set min pan distance needed before gesture is recognized
    .minDistance(1);

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <GestureDetector gesture={pan}>
        <View style={{ flex: 1, backgroundColor: "white" }}>
          <Canvas style={{ flex: 8 }}>
            {line && (
              <>
                {/* <Path
                  path={`M ${line.startX} ${line.startY} L ${line.endX} ${line.endY}`}
                  strokeWidth={strokeWidth}
                  style="stroke"
                  color={line.lineColor} 
                /> */}

                {/* Line and Vertices together make vector arrow */}
                <Line
                  p1={vec(line.startX, line.startY)}
                  // shorten line a bit so arrow tip is visible
                  p2={vec(
                    line.endX + 0.2*(line.startX - line.endX), 
                    line.endY + 0.2*(line.startY - line.endY)                    
                  )}
                  // p2={vec(line.endX, line.endY)}
                  color={line.lineColor}
                  style="stroke"
                  strokeWidth={strokeWidth} 
                />
                <Vertices
                  // These make the arrowhead of the vector
                  vertices={
                    [
                      vec(line.endX, line.endY), 
                      vec(
                        line.endX + 0.2*(line.startX - line.endX) - 0.07*(line.startY - line.endY),
                        line.endY + 0.2*(line.startY - line.endY) + 0.07*(line.startX - line.endX)
                      ),
                      vec(
                        line.endX + 0.2*(line.startX - line.endX) + 0.07*(line.startY - line.endY),
                        line.endY + 0.2*(line.startY - line.endY) - 0.07*(line.startX - line.endX)
                      )
                    ]
                  }
                  color={line.lineColor}
                />
              </>
            )}
            <Circle 
              cx={ball.ballX}
              cy={ball.ballY}
              r={ball.ballRadius}
              color={ball.ballColor}
              style="fill"
            />
          </Canvas>
        </View>
      </GestureDetector>
    </GestureHandlerRootView>
  );
}