import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { router } from 'expo-router';
import {
  Home,
  CreditCard,
  ArrowLeftRight,
  User,
} from 'lucide-react-native';

const TABS = [
  { key: 'home', label: 'Início', Icon: Home, screen: '/home' },
  { key: 'cards', label: 'Cartões', Icon: CreditCard, screen: '/cards' },
  { key: 'transactions', label: 'Transações', Icon: ArrowLeftRight, screen: '/transactions' },
  { key: 'profile', label: 'Perfil', Icon: User, screen: '/profile' },
];

interface BottomNavProps {
  activeTab: string;
}

export function BottomNav({ activeTab }: BottomNavProps) {
  return (
    <View style={styles.container}>
      <View style={styles.nav}>
        {TABS.map((tab) => {
          const isActive = activeTab === tab.key;
          return (
            <TouchableOpacity
              key={tab.key}
              style={styles.tab}
              activeOpacity={0.7}
              onPress={() => {
                if (tab.key !== activeTab) {
                  router.replace(tab.screen);
                }
              }}
            >
              {isActive && <View style={styles.indicator} />}
              <View style={[styles.iconWrapper, isActive && styles.iconWrapperActive]}>
                <tab.Icon
                  size={22}
                  color={isActive ? '#000000' : '#999999'}
                  strokeWidth={isActive ? 2 : 1.5}
                />
              </View>
              <Text style={[styles.label, isActive && styles.labelActive]}>
                {tab.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    paddingBottom: 10,
    paddingTop: 8,
    backgroundColor: '#FFFFFF',
    borderTopWidth: 1,
    borderTopColor: '#F0F0F0',
    zIndex: 100,
  },
  nav: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'flex-end',
    paddingHorizontal: 8,
  },
  tab: {
    alignItems: 'center',
    gap: 4,
    paddingVertical: 6,
    flex: 1,
    position: 'relative',
  },
  iconWrapper: {
    width: 44,
    height: 32,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconWrapperActive: {
    backgroundColor: '#F5F5F5',
  },
  label: {
    fontSize: 10,
    color: '#999999',
    fontWeight: '500',
  },
  labelActive: {
    color: '#000000',
    fontWeight: '700',
  },
  indicator: {
    position: 'absolute',
    top: 0,
    width: 24,
    height: 3,
    borderRadius: 2,
    backgroundColor: '#000000',
  },
});
