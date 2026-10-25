import React from 'react';
import { View, StyleSheet } from 'react-native';

interface LogoProps {
  size?: number;
  color?: string;
}

// Logo rendered as native Views instead of SVG
export function Logo({ size = 80, color = '#000000' }: LogoProps) {
  const s = size;
  return (
    <View style={[styles.container, { width: s, height: s }]}>
      {/* Top ribbon */}
      <View style={[styles.ribbon, { backgroundColor: color, top: s * 0.05, left: s * 0.3, width: s * 0.4, height: s * 0.45, borderRadius: s * 0.12, transform: [{ rotate: '45deg' }] }]} />
      {/* Bottom ribbon */}
      <View style={[styles.ribbon, { backgroundColor: color, opacity: 0.75, top: s * 0.5, left: s * 0.3, width: s * 0.4, height: s * 0.45, borderRadius: s * 0.12, transform: [{ rotate: '45deg' }] }]} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { position: 'relative', alignItems: 'center', justifyContent: 'center' },
  ribbon: { position: 'absolute' },
});
