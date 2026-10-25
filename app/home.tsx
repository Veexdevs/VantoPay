import React, { useEffect, useRef, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Dimensions,
  TouchableOpacity,
  Animated as RNAnimated,
} from 'react-native';
import { router } from 'expo-router';
import {
  CreditCard,
  ArrowUpRight,
  ArrowDownLeft,
  Plus,
  QrCode,
  PiggyBank,
  TrendingUp,
  Bell,
  Shield,
  Zap,
  Eye,
  EyeOff,
  ChevronRight,
  Wallet,
  Music,
  Briefcase,
  UtensilsCrossed,
  Play,
  ArrowDown,
  Car,
  Star,
} from '../components/Icons';
import { Logo } from '../components/Logo';
import { BottomNav } from '../components/BottomNav';

const { width } = Dimensions.get('window');

const TRANSACTIONS = [
  { id: '1', name: 'Spotify Premium', amount: -21.90, type: 'expense' as const, category: 'Entretenimento', time: '14:32', icon: 'music' },
  { id: '2', name: 'Salário', amount: 8500.00, type: 'income' as const, category: 'Receita', time: '09:00', icon: 'briefcase' },
  { id: '3', name: 'iFood', amount: -45.80, type: 'expense' as const, category: 'Alimentação', time: 'Ontem', icon: 'utensils' },
  { id: '4', name: 'Netflix', amount: -39.90, type: 'expense' as const, category: 'Entretenimento', time: 'Ontem', icon: 'play' },
  { id: '5', name: 'Transferência recebida', amount: 250.00, type: 'income' as const, category: 'Transferência', time: 'Seg', icon: 'arrow-down' },
  { id: '6', name: 'Uber', amount: -28.50, type: 'expense' as const, category: 'Transporte', time: 'Seg', icon: 'car' },
];

const QUICK_ACTIONS = [
  { icon: QrCode, label: 'PIX', key: 'pix' },
  { icon: ArrowUpRight, label: 'Transferir', key: 'send' },
  { icon: ArrowDownLeft, label: 'Receber', key: 'receive' },
  { icon: Plus, label: 'Recarga', key: 'topup' },
];

const FEATURE_ICONS: Record<string, any> = {
  music: Music,
  briefcase: Briefcase,
  utensils: UtensilsCrossed,
  play: Play,
  'arrow-down': ArrowDown,
  car: Car,
};

function getIcon(name: string) {
  return FEATURE_ICONS[name] || Star;
}

export default function HomeScreen() {
  const [balanceVisible, setBalanceVisible] = useState(true);
  const cardScale = useRef(new RNAnimated.Value(0.8)).current;
  const cardOpacity = useRef(new RNAnimated.Value(0)).current;
  const quickActionsOpacity = useRef(new RNAnimated.Value(0)).current;
  const featuresOpacity = useRef(new RNAnimated.Value(0)).current;
  const transactionsOpacity = useRef(new RNAnimated.Value(0)).current;

  useEffect(() => {
    RNAnimated.sequence([
      RNAnimated.spring(cardScale, { toValue: 1.02, friction: 5, tension: 60, useNativeDriver: true }),
      RNAnimated.timing(cardScale, { toValue: 1, duration: 300, useNativeDriver: true }),
    ]).start();
    RNAnimated.timing(cardOpacity, { toValue: 1, duration: 600, useNativeDriver: true }).start();
    RNAnimated.sequence([RNAnimated.delay(200), RNAnimated.timing(quickActionsOpacity, { toValue: 1, duration: 500, useNativeDriver: true })]).start();
    RNAnimated.sequence([RNAnimated.delay(400), RNAnimated.timing(featuresOpacity, { toValue: 1, duration: 500, useNativeDriver: true })]).start();
    RNAnimated.sequence([RNAnimated.delay(600), RNAnimated.timing(transactionsOpacity, { toValue: 1, duration: 500, useNativeDriver: true })]).start();
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <View style={styles.headerLeft}>
          <View style={styles.avatar}><Text style={styles.avatarText}>VP</Text></View>
          <View>
            <Text style={styles.greeting}>Olá, Bem-vindo</Text>
            <Text style={styles.name}>VantoPay</Text>
          </View>
        </View>
        <TouchableOpacity style={styles.notificationBtn}>
          <Bell size={22} color="#000" />
          <View style={styles.badge} />
        </TouchableOpacity>
      </View>

      <ScrollView style={styles.scroll} showsVerticalScrollIndicator={false} contentContainerStyle={styles.scrollContent}>
        <View style={styles.cardWrapper}>
          <RNAnimated.View style={[styles.balanceCard, { transform: [{ scale: cardScale }], opacity: cardOpacity }]}>
            <View style={styles.cardTop}>
              <View style={styles.cardHeader}>
                <Logo size={28} color="#FFFFFF" />
                <Text style={styles.cardType}>VIRTUAL • VANTO</Text>
              </View>
              <TouchableOpacity onPress={() => setBalanceVisible(!balanceVisible)} style={styles.eyeBtn}>
                {balanceVisible ? <Eye size={20} color="#FFFFFF88" /> : <EyeOff size={20} color="#FFFFFF88" />}
              </TouchableOpacity>
            </View>
            <View style={styles.balanceSection}>
              <Text style={styles.balanceLabel}>Saldo disponível</Text>
              <Text style={styles.balanceValue}>{balanceVisible ? 'R$ 12.847,30' : 'R$ •••••••'}</Text>
            </View>
            <View style={styles.cardBottom}>
              <View style={styles.cardNumberSection}>
                <Text style={styles.cardNumber}>•••• •••• •••• 4289</Text>
              </View>
              <View style={styles.cardIcons}>
                <CreditCard size={18} color="#FFFFFF88" />
                <Wallet size={18} color="#FFFFFF88" />
              </View>
            </View>
            <View style={styles.cardDecor1} />
            <View style={styles.cardDecor2} />
            <View style={styles.cardDecor3} />
          </RNAnimated.View>
        </View>

        <RNAnimated.View style={[styles.quickActions, { opacity: quickActionsOpacity }]}>
          {QUICK_ACTIONS.map((action) => (
            <TouchableOpacity
              key={action.key}
              style={styles.quickActionBtn}
              activeOpacity={0.7}
              onPress={() => {
                if (action.key === 'send') router.push('/send');
                if (action.key === 'receive') router.push('/receive');
              }}
            >
              <View style={styles.quickActionIcon}>
                <action.icon size={22} color="#000000" />
              </View>
              <Text style={styles.quickActionLabel}>{action.label}</Text>
            </TouchableOpacity>
          ))}
        </RNAnimated.View>

        <RNAnimated.View style={[styles.featuresSection, { opacity: featuresOpacity }]}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Serviços</Text>
            <TouchableOpacity><Text style={styles.sectionLink}>Ver todos</Text></TouchableOpacity>
          </View>
          <View style={styles.featuresGrid}>
            {[
              { icon: PiggyBank, label: 'Reservar', desc: 'Economize' },
              { icon: TrendingUp, label: 'Investir', desc: 'Rendimento' },
              { icon: Zap, label: 'PIX', desc: 'Instantâneo' },
              { icon: Shield, label: 'Seguro', desc: 'Proteção' },
            ].map((item) => (
              <TouchableOpacity key={item.label} style={styles.featureItem} activeOpacity={0.7}>
                <View style={styles.featureIconBg}><item.icon size={24} color="#000000" /></View>
                <Text style={styles.featureLabel}>{item.label}</Text>
                <Text style={styles.featureDesc}>{item.desc}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </RNAnimated.View>

        <RNAnimated.View style={[styles.transactionsSection, { opacity: transactionsOpacity }]}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Transações</Text>
            <TouchableOpacity onPress={() => router.push('/transactions')}>
              <Text style={styles.sectionLink}>Ver todas</Text>
            </TouchableOpacity>
          </View>
          {TRANSACTIONS.slice(0, 4).map((tx) => {
            const IconComp = getIcon(tx.icon);
            return (
              <View key={tx.id} style={styles.transactionItem}>
                <View style={styles.txRow}>
                  <View style={[styles.txIcon, { backgroundColor: tx.type === 'income' ? '#F0F0F0' : '#F8F8F8' }]}>
                    <IconComp size={18} color="#000000" />
                  </View>
                  <View style={styles.txInfo}>
                    <Text style={styles.txName}>{tx.name}</Text>
                    <Text style={styles.txCat}>{tx.category}</Text>
                  </View>
                  <View style={styles.txAmount}>
                    <Text style={[styles.txValue, { color: tx.type === 'income' ? '#000000' : '#666666' }]}>
                      {tx.type === 'income' ? '+' : '-'} R$ {Math.abs(tx.amount).toFixed(2)}
                    </Text>
                    <Text style={styles.txTime}>{tx.time}</Text>
                  </View>
                </View>
              </View>
            );
          })}
          <TouchableOpacity style={styles.seeAllBtn} onPress={() => router.push('/transactions')}>
            <Text style={styles.seeAllText}>Ver todas as transações</Text>
            <ChevronRight size={16} color="#000000" />
          </TouchableOpacity>
        </RNAnimated.View>
      </ScrollView>
      <BottomNav activeTab="home" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FFFFFF' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 24, paddingTop: 50, paddingBottom: 20 },
  headerLeft: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  avatar: { width: 44, height: 44, borderRadius: 22, backgroundColor: '#000000', alignItems: 'center', justifyContent: 'center' },
  avatarText: { color: '#FFFFFF', fontSize: 14, fontWeight: '700', letterSpacing: 1 },
  greeting: { fontSize: 13, color: '#888888' },
  name: { fontSize: 17, fontWeight: '700', color: '#000000' },
  notificationBtn: { width: 44, height: 44, borderRadius: 22, backgroundColor: '#F5F5F5', alignItems: 'center', justifyContent: 'center', position: 'relative' },
  badge: { position: 'absolute', top: 10, right: 10, width: 8, height: 8, borderRadius: 4, backgroundColor: '#000000', borderWidth: 2, borderColor: '#FFFFFF' },
  scroll: { flex: 1 },
  scrollContent: { paddingBottom: 100 },
  cardWrapper: { paddingHorizontal: 24 },
  balanceCard: { backgroundColor: '#000000', borderRadius: 24, padding: 24, minHeight: 200, justifyContent: 'space-between', overflow: 'hidden' },
  cardDecor1: { position: 'absolute', top: -30, right: -30, width: 120, height: 120, borderRadius: 60, borderWidth: 30, borderColor: '#FFFFFF08' },
  cardDecor2: { position: 'absolute', bottom: -40, left: -40, width: 150, height: 150, borderRadius: 75, borderWidth: 40, borderColor: '#FFFFFF05' },
  cardDecor3: { position: 'absolute', top: '50%', right: 20, width: 80, height: 80, borderRadius: 40, backgroundColor: '#FFFFFF05' },
  cardTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  cardHeader: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  cardType: { color: '#FFFFFF88', fontSize: 11, fontWeight: '600', letterSpacing: 2 },
  eyeBtn: { padding: 4 },
  balanceSection: { marginTop: 20 },
  balanceLabel: { color: '#FFFFFF88', fontSize: 13, marginBottom: 4 },
  balanceValue: { color: '#FFFFFF', fontSize: 32, fontWeight: '800', letterSpacing: -1 },
  cardBottom: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 16 },
  cardNumberSection: { flex: 1 },
  cardNumber: { color: '#FFFFFF88', fontSize: 14, fontWeight: '500', letterSpacing: 2 },
  cardIcons: { flexDirection: 'row', gap: 12 },
  quickActions: { flexDirection: 'row', justifyContent: 'space-between', paddingHorizontal: 24, marginTop: 28 },
  quickActionBtn: { alignItems: 'center', gap: 8, flex: 1 },
  quickActionIcon: { width: 56, height: 56, borderRadius: 18, backgroundColor: '#F5F5F5', alignItems: 'center', justifyContent: 'center', borderWidth: 1, borderColor: '#E8E8E8' },
  quickActionLabel: { fontSize: 12, fontWeight: '600', color: '#000000' },
  featuresSection: { marginTop: 32, paddingHorizontal: 24 },
  sectionHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 },
  sectionTitle: { fontSize: 18, fontWeight: '700', color: '#000000' },
  sectionLink: { fontSize: 13, fontWeight: '600', color: '#666666' },
  featuresGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  featureItem: { width: (width - 72) / 2, backgroundColor: '#F8F8F8', borderRadius: 18, padding: 16, borderWidth: 1, borderColor: '#EEEEEE' },
  featureIconBg: { width: 44, height: 44, borderRadius: 14, backgroundColor: '#FFFFFF', alignItems: 'center', justifyContent: 'center', marginBottom: 10, borderWidth: 1, borderColor: '#E8E8E8' },
  featureLabel: { fontSize: 14, fontWeight: '700', color: '#000000', marginBottom: 2 },
  featureDesc: { fontSize: 12, color: '#888888' },
  transactionsSection: { marginTop: 32, paddingHorizontal: 24 },
  transactionItem: { borderBottomWidth: 1, borderBottomColor: '#F0F0F0' },
  txRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 12 },
  txIcon: { width: 40, height: 40, borderRadius: 12, alignItems: 'center', justifyContent: 'center' },
  txInfo: { flex: 1, marginLeft: 12 },
  txName: { fontSize: 14, fontWeight: '600', color: '#000000', marginBottom: 2 },
  txCat: { fontSize: 12, color: '#888888' },
  txAmount: { alignItems: 'flex-end' },
  txValue: { fontSize: 14, fontWeight: '700' },
  txTime: { fontSize: 11, color: '#AAAAAA', marginTop: 2 },
  seeAllBtn: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8, marginTop: 16, paddingVertical: 12 },
  seeAllText: { fontSize: 14, fontWeight: '600', color: '#000000' },
});
