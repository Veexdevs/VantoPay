import React from 'react';
import { Ionicons, MaterialIcons, Feather } from '@expo/vector-icons';

type IconProps = {
  size?: number;
  color?: string;
  strokeWidth?: number;
};

// Map Lucide icon names to Expo Vector Icons equivalents
export function Bell(props: IconProps) {
  return <Ionicons name="notifications-outline" size={props.size || 24} color={props.color || '#000'} />;
}
export function Eye(props: IconProps) {
  return <Feather name="eye" size={props.size || 24} color={props.color || '#000'} />;
}
export function EyeOff(props: IconProps) {
  return <Feather name="eye-off" size={props.size || 24} color={props.color || '#000'} />;
}
export function CreditCard(props: IconProps) {
  return <Feather name="credit-card" size={props.size || 24} color={props.color || '#000'} />;
}
export function Wallet(props: IconProps) {
  return <Feather name="briefcase" size={props.size || 24} color={props.color || '#000'} />;
}
export function ArrowUpRight(props: IconProps) {
  return <Feather name="arrow-up-right" size={props.size || 24} color={props.color || '#000'} />;
}
export function ArrowDownLeft(props: IconProps) {
  return <Feather name="arrow-down-left" size={props.size || 24} color={props.color || '#000'} />;
}
export function Plus(props: IconProps) {
  return <Feather name="plus" size={props.size || 24} color={props.color || '#000'} />;
}
export function QrCode(props: IconProps) {
  return <Feather name="grid" size={props.size || 24} color={props.color || '#000'} />;
}
export function PiggyBank(props: IconProps) {
  return <Feather name="heart" size={props.size || 24} color={props.color || '#000'} />;
}
export function TrendingUp(props: IconProps) {
  return <Feather name="trending-up" size={props.size || 24} color={props.color || '#000'} />;
}
export function TrendingDown(props: IconProps) {
  return <Feather name="trending-down" size={props.size || 24} color={props.color || '#000'} />;
}
export function Shield(props: IconProps) {
  return <Feather name="shield" size={props.size || 24} color={props.color || '#000'} />;
}
export function Zap(props: IconProps) {
  return <Feather name="zap" size={props.size || 24} color={props.color || '#000'} />;
}
export function ChevronRight(props: IconProps) {
  return <Feather name="chevron-right" size={props.size || 24} color={props.color || '#000'} />;
}
export function Home(props: IconProps) {
  return <Feather name="home" size={props.size || 24} color={props.color || '#000'} />;
}
export function ArrowLeftRight(props: IconProps) {
  return <Feather name="repeat" size={props.size || 24} color={props.color || '#000'} />;
}
export function User(props: IconProps) {
  return <Feather name="user" size={props.size || 24} color={props.color || '#000'} />;
}
export function Lock(props: IconProps) {
  return <Feather name="lock" size={props.size || 24} color={props.color || '#000'} />;
}
export function Unlock(props: IconProps) {
  return <Feather name="unlock" size={props.size || 24} color={props.color || '#000'} />;
}
export function Settings(props: IconProps) {
  return <Feather name="settings" size={props.size || 24} color={props.color || '#000'} />;
}
export function Snowflake(props: IconProps) {
  return <MaterialIcons name="ac-unit" size={props.size || 24} color={props.color || '#000'} />;
}
export function Download(props: IconProps) {
  return <Feather name="download" size={props.size || 24} color={props.color || '#000'} />;
}
export function Search(props: IconProps) {
  return <Feather name="search" size={props.size || 24} color={props.color || '#000'} />;
}
export function Filter(props: IconProps) {
  return <Feather name="filter" size={props.size || 24} color={props.color || '#000'} />;
}
export function Calendar(props: IconProps) {
  return <Feather name="calendar" size={props.size || 24} color={props.color || '#000'} />;
}
export function BarChart3(props: IconProps) {
  return <Feather name="bar-chart-2" size={props.size || 24} color={props.color || '#000'} />;
}
export function Fingerprint(props: IconProps) {
  return <MaterialIcons name="fingerprint" size={props.size || 24} color={props.color || '#000'} />;
}
export function Moon(props: IconProps) {
  return <Feather name="moon" size={props.size || 24} color={props.color || '#000'} />;
}
export function Globe(props: IconProps) {
  return <Feather name="globe" size={props.size || 24} color={props.color || '#000'} />;
}
export function HelpCircle(props: IconProps) {
  return <Feather name="help-circle" size={props.size || 24} color={props.color || '#000'} />;
}
export function LogOut(props: IconProps) {
  return <Feather name="log-out" size={props.size || 24} color={props.color || '#000'} />;
}
export function Star(props: IconProps) {
  return <Feather name="star" size={props.size || 24} color={props.color || '#000'} />;
}
export function Smartphone(props: IconProps) {
  return <Feather name="smartphone" size={props.size || 24} color={props.color || '#000'} />;
}
export function Share2(props: IconProps) {
  return <Feather name="share-2" size={props.size || 24} color={props.color || '#000'} />;
}
export function Copy(props: IconProps) {
  return <Feather name="copy" size={props.size || 24} color={props.color || '#000'} />;
}
export function Check(props: IconProps) {
  return <Feather name="check" size={props.size || 24} color={props.color || '#000'} />;
}
export function X(props: IconProps) {
  return <Feather name="x" size={props.size || 24} color={props.color || '#000'} />;
}
export function ArrowDown(props: IconProps) {
  return <Feather name="arrow-down" size={props.size || 24} color={props.color || '#000'} />;
}
export function Clock(props: IconProps) {
  return <Feather name="clock" size={props.size || 24} color={props.color || '#000'} />;
}
export function Keyboard(props: IconProps) {
  return <Feather name="type" size={props.size || 24} color={props.color || '#000'} />;
}
export function Hash(props: IconProps) {
  return <Feather name="hash" size={props.size || 24} color={props.color || '#000'} />;
}
export function Building2(props: IconProps) {
  return <Feather name="home" size={props.size || 24} color={props.color || '#000'} />;
}
export function Banknote(props: IconProps) {
  return <Feather name="dollar-sign" size={props.size || 24} color={props.color || '#000'} />;
}
export function Wifi(props: IconProps) {
  return <Feather name="wifi" size={props.size || 24} color={props.color || '#000'} />;
}
// Transaction icons
export function Music(props: IconProps) {
  return <Feather name="music" size={props.size || 24} color={props.color || '#000'} />;
}
export function Briefcase(props: IconProps) {
  return <Feather name="briefcase" size={props.size || 24} color={props.color || '#000'} />;
}
export function UtensilsCrossed(props: IconProps) {
  return <Feather name="coffee" size={props.size || 24} color={props.color || '#000'} />;
}
export function Play(props: IconProps) {
  return <Feather name="play" size={props.size || 24} color={props.color || '#000'} />;
}
export function Car(props: IconProps) {
  return <Feather name="truck" size={props.size || 24} color={props.color || '#000'} />;
}
export function ShoppingBag(props: IconProps) {
  return <Feather name="shopping-bag" size={props.size || 24} color={props.color || '#000'} />;
}
export function Heart(props: IconProps) {
  return <Feather name="heart" size={props.size || 24} color={props.color || '#000'} />;
}
