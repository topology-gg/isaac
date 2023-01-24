//import ScreenOrientation from 'expo-screen-orientation';
import React, { useState, useEffect } from "react";
import { View, Dimensions } from "react-native";
import { Gesture, GestureDetector, GestureHandlerRootView } from "react-native-gesture-handler";
import { Canvas, Circle, Path } from "@shopify/react-native-skia";
//import { max } from 'react-native-reanimated';
//import { Circle } from "react-native-svg";

// Define path and circle objects
interface IPath {
  startX: number;
  startY: number;
  endX: number;
  endY: number;
  color: string;
}
interface ICircle {
  circleX: number;
  circleY: number;
  radius: number;
  color: string;
  style: string;
}

export default function App() {    
  // Get dimensions of device screen
  const { width, height } = Dimensions.get("window");

  // Set initial position of the circle and the starting point of the path to be drawn
  // This is also the position of the circle/ball when launched
  const launchX = 0.3 * width;
  const launchY = 0.7 * height;
  // Set max distance allowed from initial position, in order to begin gesture
  const maxDistToBeginGesture = 25;
  // Set max distance circle/path can be pulled from launch position
  const maxDistToLaunchPosition = 0.33 * Math.min(width, height);
  // Set max launch velocity magnitude, corresponding to max pull from launch position
  const maxVelocity = 100;

  const radius = 10; // for circle
  const strokeWidth = 5; // for path
  const color = "green"; // for both circle and path

  // Use state to initialize and store path and circle data
  const [path, setPath] = useState<IPath | null>(null);
  const [circle, setCircle] = useState<ICircle>({
    circleX: launchX,
    circleY: launchY,
    radius: radius,
    color: color,
    style: "fill"
  });
  // Use state to initialize and store final x and y positions of circle before launch
  const [finalX, setFinalX] = useState<number>(launchX);
  const [finalY, setFinalY] = useState<number>(launchY);

  const pan = Gesture.Pan()
    // Run the gesture on JS thread, instead of native thread
    // Maybe this is so we can pass values to skia canvas(???)
    .runOnJS(true)

    .onStart((current) => {
      const distToLaunchPosition = Math.sqrt((current.x - launchX)**2 + (current.y - launchY)**2);
      // If current distance is within the maximum distance allowed 
      // to begin gesture, and there is no path yet...
      if (distToLaunchPosition <= maxDistToBeginGesture && !path) {
        setPath({
          startX: current.x,
          startY: current.y,
          endX: launchX,
          endY: launchY,
          color: color,
        });
        setCircle({
          ...circle,
          circleX: current.x,
          circleY: current.y,
        });
        setFinalX(current.x);
        setFinalY(current.y);
        console.log('current.x =',current.x);
        console.log('current.y =',current.y);
      }
    })

    .onUpdate((current) => {
      if (path) {
        const distToLaunchPosition = Math.sqrt((current.x - launchX)**2 + (current.y - launchY)**2);
      // If current distance is within the maximum distance allowed 
      // away from launch position...
        if (distToLaunchPosition <= maxDistToLaunchPosition) {
          setPath({
            ...path,
            startX: current.x,
            startY: current.y,
          });
          setCircle({
            ...circle,
            circleX: current.x,
            circleY: current.y,
          });
          setFinalX(current.x);
          setFinalY(current.y);
          console.log('current.x = ',current.x);
          console.log('current.y = ',current.y);
        } else {
          // Otherwise reduce x and y values so that circle is within 
          // max allowed distance. 
          // Path stops here, but points to current position of gesture
          const ratio = maxDistToLaunchPosition / distToLaunchPosition;
          const reducedCurrentX = launchX + ratio * (current.x - launchX);
          const reducedCurrentY = launchY + ratio * (current.y - launchY);
          setPath({
            ...path,
            startX: reducedCurrentX,
            startY: reducedCurrentY,
          });
          setCircle({
            ...circle,
            circleX: reducedCurrentX,
            circleY: reducedCurrentY,
          });
          setFinalX(reducedCurrentX);
          setFinalY(reducedCurrentY);
          console.log('current.x =', current.x);
          console.log('current.y =', current.y);
          console.log('reducedCurrentX =', reducedCurrentX);
          console.log('reducedCurrentY =', reducedCurrentY);
        }
      }
    })

    .onEnd(() => {
      console.log('finalX =', finalX);
      console.log('finalY =', finalY);
      const finalDistToLaunchPosition = Math.sqrt((finalX - launchX)**2 + (finalY - launchY)**2);

      // Launch velocity is proportional to final distance / max allowed distance
      const launchVelocityFloat = maxVelocity * finalDistToLaunchPosition / maxDistToLaunchPosition;
      // convert to integer
      const launchVelocity = launchVelocityFloat.toFixed(0);
      console.log('launchVelocity =', launchVelocity);

      // Angle is found using device coordinate system (= left-handed system 
      // with origin at upper left of screen, with +x right, +y down).
      // To switch coordinate system (to right-handed with +x right, +y up)
      // and to make launch angle opposite direction circle was pulled, 
      // use extra negative sign, and/or add/subtract 180.
      if (finalY >= launchY) {
        // If in 1st or 2nd quadrant
        const launchAngleDegFloat = -Math.acos((finalX - launchX)/finalDistToLaunchPosition) * 180 / Math.PI + 180;
        // convert to integer
        const launchAngleDeg = launchAngleDegFloat.toFixed(0);
        console.log('launchAngleDeg =', launchAngleDeg);
      } else {
        // If in 3rd or 4th quadrant
        const launchAngleDegFloat = Math.acos((finalX - launchX)/finalDistToLaunchPosition) * 180 / Math.PI - 180;
        // convert to integer
        const launchAngleDeg = launchAngleDegFloat.toFixed(0);
        console.log('launchAngleDeg =', launchAngleDeg);
      }

      // Reset path, circle, and final values
      setPath(null);
      setCircle({
        ...circle,
        circleX: launchX,
        circleY: launchY,
      });
      setFinalX(launchX);
      setFinalY(launchY);
    })

    .minDistance(1);

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <GestureDetector gesture={pan}>
        <View style={{ flex: 1, backgroundColor: "white" }}>
          <Canvas style={{ flex: 8 }}>
            {path && (
              <Path
                path={`M ${path.startX} ${path.startY} L ${path.endX} ${path.endY}`}
                strokeWidth={strokeWidth}
                style="stroke"
                color={path.color}
              />
            )}
            <Circle 
              cx={circle.circleX}
              cy={circle.circleY}
              r={circle.radius}
              color={circle.color}
              style="fill"
            />
          </Canvas>
        </View>
      </GestureDetector>
    </GestureHandlerRootView>
  );
}