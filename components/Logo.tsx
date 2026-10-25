import React from 'react';
import { Svg, Path, Defs, LinearGradient, Stop } from 'react-native-svg';

interface LogoProps {
  size?: number;
  color?: string;
}

export function Logo({ size = 80, color = '#000000' }: LogoProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 100 100">
      <Defs>
        <LinearGradient id="logoGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <Stop offset="0%" stopColor={color} stopOpacity="1" />
          <Stop offset="100%" stopColor={color} stopOpacity="0.7" />
        </LinearGradient>
      </Defs>
      <Path
        d="M50 10 C50 10, 65 25, 65 35 C65 45, 50 45, 35 55 C20 65, 15 75, 15 75 C15 75, 30 90, 30 90 C30 90, 35 75, 50 65 C65 55, 65 55, 65 45 C65 35, 50 10, 50 10 Z"
        fill="url(#logoGrad)"
      />
      <Path
        d="M50 90 C50 90, 35 75, 35 65 C35 55, 50 55, 65 45 C80 35, 85 25, 85 25 C85 25, 70 10, 70 10 C70 10, 65 25, 50 35 C35 45, 35 45, 35 55 C35 65, 50 90, 50 90 Z"
        fill="url(#logoGrad)"
        opacity="0.85"
      />
    </Svg>
  );
}

export function LogoIcon({ size = 24, color = '#000000' }: LogoProps) {
  return (
    <Svg width={size} height={size} viewBox="0 0 100 100">
      <Path
        d="M50 10 C50 10, 65 25, 65 35 C65 45, 50 45, 35 55 C20 65, 15 75, 15 75 C15 75, 30 90, 30 90 C30 90, 35 75, 50 65 C65 55, 65 55, 65 45 C65 35, 50 10, 50 10 Z"
        fill={color}
      />
      <Path
        d="M50 90 C50 90, 35 75, 35 65 C35 55, 50 55, 65 45 C80 35, 85 25, 85 25 C85 25, 70 10, 70 10 C70 10, 65 25, 50 35 C35 45, 35 45, 35 55 C35 65, 50 90, 50 90 Z"
        fill={color}
        opacity="0.75"
      />
    </Svg>
  );
}
