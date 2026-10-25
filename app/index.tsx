import { useEffect, useRef, useState } from 'react';
import { View, Text, StyleSheet, Dimensions, Animated as RNAnimated, Easing } from 'react-native';
import { router } from 'expo-router';
import { Logo } from '../components/Logo';

const { width, height } = Dimensions.get('window');

export default function SplashScreen() {
  const logoScale = useRef(new RNAnimated.Value(0)).current;
  const logoRotate = useRef(new RNAnimated.Value(-180)).current;
  const titleOpacity = useRef(new RNAnimated.Value(0)).current;
  const titleTranslateY = useRef(new RNAnimated.Value(30)).current;
  const progressWidth = useRef(new RNAnimated.Value(0)).current;
  const containerOpacity = useRef(new RNAnimated.Value(1)).current;
  const particleOpacity = useRef(new RNAnimated.Value(0)).current;

  useEffect(() => {
    RNAnimated.sequence([
      RNAnimated.parallel([
        RNAnimated.spring(logoScale, {
          toValue: 1,
          friction: 5,
          tension: 60,
          useNativeDriver: true,
        }),
        RNAnimated.timing(logoRotate, {
          toValue: 0,
          duration: 1200,
          easing: Easing.out(Easing.cubic),
          useNativeDriver: true,
        }),
      ]),
      RNAnimated.sequence([
        RNAnimated.timing(logoScale, {
          toValue: 0.95,
          duration: 300,
          useNativeDriver: true,
        }),
        RNAnimated.timing(logoScale, {
          toValue: 1.05,
          duration: 300,
          useNativeDriver: true,
        }),
        RNAnimated.timing(logoScale, {
          toValue: 1,
          duration: 300,
          useNativeDriver: true,
        }),
      ]),
    ]).start();

    RNAnimated.parallel([
      RNAnimated.sequence([
        RNAnimated.delay(800),
        RNAnimated.timing(titleOpacity, {
          toValue: 1,
          duration: 600,
          useNativeDriver: true,
        }),
      ]),
      RNAnimated.sequence([
        RNAnimated.delay(800),
        RNAnimated.timing(titleTranslateY, {
          toValue: 0,
          duration: 600,
          easing: Easing.out(Easing.exp),
          useNativeDriver: true,
        }),
      ]),
      RNAnimated.sequence([
        RNAnimated.delay(300),
        RNAnimated.timing(particleOpacity, {
          toValue: 1,
          duration: 500,
          useNativeDriver: true,
        }),
      ]),
    ]).start();

    RNAnimated.sequence([
      RNAnimated.delay(1200),
      RNAnimated.timing(progressWidth, {
        toValue: 100,
        duration: 1800,
        easing: Easing.inOut(Easing.ease),
        useNativeDriver: false,
      }),
    ]).start();

    const timer = setTimeout(() => {
      RNAnimated.timing(containerOpacity, {
        toValue: 0,
        duration: 400,
        useNativeDriver: true,
      }).start(() => {
        router.replace('/home');
      });
    }, 3200);

    return () => clearTimeout(timer);
  }, []);

  return (
    <RNAnimated.View style={[styles.container, { opacity: containerOpacity }]}>
      {/* Background grid pattern */}
      <View style={styles.gridBackground}>
        {Array.from({ length: 6 }).map((_, i) => (
          <View key={`h-${i}`} style={[styles.gridLine, styles.gridLineH, { top: (i + 1) * (height / 7) }]} />
        ))}
        {Array.from({ length: 4 }).map((_, i) => (
          <View key={`v-${i}`} style={[styles.gridLine, styles.gridLineV, { left: (i + 1) * (width / 5) }]} />
        ))}
      </View>

      <View style={styles.content}>
        <RNAnimated.View
          style={[
            styles.logoContainer,
            {
              transform: [
                { scale: logoScale },
                { rotate: logoRotate.interpolate({ inputRange: [-180, 0], outputRange: ['-180deg', '0deg'] }) },
              ],
            },
          ]}
        >
          <Logo size={120} />
        </RNAnimated.View>

        <RNAnimated.Text
          style={[styles.title, { opacity: titleOpacity, transform: [{ translateY: titleTranslateY }] }]}
        >
          VantoPay
        </RNAnimated.Text>

        <RNAnimated.Text
          style={[styles.subtitle, { opacity: titleOpacity, transform: [{ translateY: titleTranslateY }] }]}
        >
          Seu dinheiro, seu ritmo
        </RNAnimated.Text>
      </View>

      {/* Loading bar */}
      <View style={styles.progressContainer}>
        <View style={styles.progressTrack}>
          <RNAnimated.View
            style={[styles.progressFill, { width: progressWidth.interpolate({ inputRange: [0, 100], outputRange: ['0%', '100%'] }) }]}
          />
        </View>
      </View>

      {/* Floating particles */}
      {Array.from({ length: 8 }).map((_, i) => (
        <RNAnimated.View
          key={i}
          style={[
            styles.particle,
            {
              width: 4 + (i % 3) * 3,
              height: 4 + (i % 3) * 3,
              left: `${10 + i * 12}%`,
              top: `${15 + (i * 17) % 70}%`,
              borderRadius: i % 2 === 0 ? 100 : 0,
              opacity: particleOpacity,
            },
          ]}
        />
      ))}
    </RNAnimated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    justifyContent: 'center',
  },
  gridBackground: {
    ...StyleSheet.absoluteFillObject,
    overflow: 'hidden',
  },
  gridLine: {
    position: 'absolute',
    backgroundColor: '#F0F0F0',
  },
  gridLineH: {
    width: '100%',
    height: 1,
  },
  gridLineV: {
    width: 1,
    height: '100%',
  },
  content: {
    alignItems: 'center',
    gap: 16,
    zIndex: 1,
  },
  logoContainer: {
    marginBottom: 20,
  },
  title: {
    fontSize: 42,
    fontWeight: '800',
    color: '#000000',
    letterSpacing: -1,
  },
  subtitle: {
    fontSize: 16,
    color: '#666666',
    fontWeight: '400',
    letterSpacing: 4,
    textTransform: 'uppercase',
  },
  progressContainer: {
    position: 'absolute',
    bottom: 80,
    width: width * 0.6,
  },
  progressTrack: {
    width: '100%',
    height: 3,
    backgroundColor: '#E8E8E8',
    borderRadius: 2,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#000000',
    borderRadius: 2,
  },
  particle: {
    position: 'absolute',
    backgroundColor: '#000000',
    opacity: 0.1,
  },
});
