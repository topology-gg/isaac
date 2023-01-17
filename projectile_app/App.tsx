import { StatusBar } from 'expo-status-bar';
import React from 'react';
import { Modal, StyleSheet, Text, View} from 'react-native';
import Animated, {
    useAnimatedGestureHandler,
    useAnimatedStyle,
    useSharedValue,
    withSpring,
} from 'react-native-reanimated';

import {
    GestureHandlerRootView,
    PanGestureHandler,
    PanGestureHandlerGestureEvent,
} from 'react-native-gesture-handler';

// To draw vector
import Svg, { Line, Marker } from 'react-native-svg';

const RADIUS = 15;

// Not yet sure why this is needed, or if there's another way to give these a type
type ContextType = {
    currentX: number;
    currentY: number;
};

function App() {
    const initialX: number = 0;
    const initialY: number = 0;

    // initialize currentX & Y values shared by animation thread
    const currentX = useSharedValue(initialX);
    const currentY = useSharedValue(initialY);
    // initialize current deltaX & Y values shared by animation thread
    const deltaX = useSharedValue(0);
    const deltaY = useSharedValue(0);

    // useAnimatedGestureHandler handles many types of gesture events
    // here it handles PanGestureHandlerGestureEvent
    const panGestureEvent = useAnimatedGestureHandler<
        PanGestureHandlerGestureEvent,
        ContextType
    >({
        // Hook `useAnimatedGestureHandler` provides some callbacks
        // We use 3 of these: onStart, onActive, onEnd
        
        // Upon touch, store currentX & Y.values as "context" object properties
        onStart: (event, context) => {
            context.currentX = currentX.value;
            context.currentY = currentY.value;
        },

        // Upon pan, find new currentX & Y.values, record translationX & Y values
        onActive: (event, context) => {
            currentX.value = event.translationX + context.currentX;
            currentY.value = event.translationY + context.currentY;
            deltaX.value = event.translationX;
            deltaY.value = event.translationY;
            
            // need to draw vector here

            console.log('translationX,Y');
            console.log(event.translationX);
            console.log(event.translationY);
        },

        // Upon untouch, spring moves ball back to origin
        onEnd: () => {
            console.log('FINAL translationX,Y');
            console.log(deltaX.value);
            console.log(deltaY.value);

            currentX.value = withSpring(initialX);
            currentY.value = withSpring(initialY);
            deltaX.value = 0;
            deltaY.value = 0;
        },
    });

    const rStyle = useAnimatedStyle(() => {
        return {
            transform: [
                {
                translateX: currentX.value,
                },
                {
                translateY: currentY.value,
                },
            ],
        };
    });

    return (
        <View style={styles.container}>
            <PanGestureHandler onGestureEvent={panGestureEvent}>
                <Animated.View style={[styles.circle, rStyle]} />
            </PanGestureHandler>
        </View>
    );
}

export default () => {
    return (
        <GestureHandlerRootView style={{ flex: 1 }}>
            <App />
        </GestureHandlerRootView>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#fff',
        alignItems: 'center',
        justifyContent: 'center',
    },
    circle: {
        width: RADIUS * 2,
        height: RADIUS * 2,
        alignItems: 'center',
        justifyContent: 'center',
        borderRadius: RADIUS,
        backgroundColor: 'rgba(0, 160, 0, 0.75)',
    },
    // vector: {
    //     length: ,
    //     height: RADIUS * 2,
    //     alignItems: 'center',
    //     justifyContent: 'center',
    //     borderRadius: RADIUS,
    //     backgroundColor: 'rgba(0, 160, 0, 0.75)',
    // },
});