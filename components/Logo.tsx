import React from 'react';
import { Image, StyleSheet, View } from 'react-native';

interface LogoProps {
  size?: number;
  color?: string;
}

export function Logo({ size = 80 }: LogoProps) {
  return (
    <View style={[styles.container, { width: size, height: size }]}>
      <Image
        source={require('../assets/vantopay-logo.png')}
        style={[styles.logo, { width: size * 0.9, height: size * 0.9 }]}
        resizeMode="contain"
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  logo: {
    // The image will fill the container proportionally
  },
});
