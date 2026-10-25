import React, { useEffect, useRef } from 'react';
import { View, StyleSheet, Animated as RNAnimated, Easing } from 'react-native';

interface AnimatedCardProps {
  children: React.ReactNode;
  style?: any;
}

export function AnimatedCard({ children, style }: AnimatedCardProps) {
  const opacity = useRef(new RNAnimated.Value(0)).current;
  const translateY = useRef(new RNAnimated.Value(20)).current;

  useEffect(() => {
    RNAnimated.parallel([
      RNAnimated.timing(opacity, {
        toValue: 1,
        duration: 600,
        useNativeDriver: true,
      }),
      RNAnimated.timing(translateY, {
        toValue: 0,
        duration: 600,
        easing: Easing.out(Easing.exp),
        useNativeDriver: true,
      }),
    ]).start();
  }, []);

  return (
    <RNAnimated.View
      style={[
        styles.container,
        style,
        { opacity, transform: [{ translateY }] },
      ]}
    >
      <View style={styles.card}>
        {children}
      </View>
    </RNAnimated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: 12,
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E8E8E8',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 8,
    elevation: 2,
  },
});
