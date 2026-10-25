import React, { useEffect, useRef } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Animated as RNAnimated } from 'react-native';
import { router } from 'expo-router';
import { Plus, Lock, Unlock, Eye, EyeOff, Settings, Snowflake, QrCode, ChevronRight, Wifi } from '../components/Icons';
import { BottomNav } from '../components/BottomNav';
import { Logo } from '../components/Logo';

const CARDS = [
  { id: '1', name: 'Vanto Black', number: '4289', balance: 'R$ 8.420,50', type: 'Crédito', limit: 'R$ 15.000', isDark: true },
  { id: '2', name: 'Vanto Virtual', number: '7832', balance: 'R$ 4.426,80', type: 'Débito', limit: 'Sem limite', isDark: false },
  { id: '3', name: 'Vanto Save', number: '1056', balance: 'R$ 1.240,00', type: 'Poupança', limit: 'R$ 5.000', isDark: false },
];

function CardComponent({ card, index }: { card: typeof CARDS[0]; index: number }) {
  const scaleAnim = useRef(new RNAnimated.Value(0.9)).current;
  const opacityAnim = useRef(new RNAnimated.Value(0)).current;

  useEffect(() => {
    RNAnimated.parallel([
      RNAnimated.sequence([RNAnimated.delay(200 * index), RNAnimated.spring(scaleAnim, { toValue: 1, friction: 5, tension: 60, useNativeDriver: true })]),
      RNAnimated.sequence([RNAnimated.delay(100 * index), RNAnimated.timing(opacityAnim, { toValue: 1, duration: 500, useNativeDriver: true })]),
    ]).start();
  }, []);

  const color = card.isDark ? '#FFFFFF' : '#000000';
  const mutedColor = card.isDark ? '#FFFFFF88' : '#888888';

  return (
    <RNAnimated.View style={[styles.card, { backgroundColor: card.isDark ? '#000000' : '#FFFFFF' }, { transform: [{ scale: scaleAnim }], opacity: opacityAnim }]}>
      <View style={styles.cardPattern} />
      <View style={styles.cardPattern2} />
      <View style={styles.cardHeader}>
        <Logo size={30} color={color} />
        <View style={[styles.cardChip, { borderColor: card.isDark ? '#FFFFFF44' : '#00000022' }]} />
        <Wifi size={20} color={card.isDark ? '#FFFFFF66' : '#00000044'} />
      </View>
      <View style={styles.cardInfo}>
        <Text style={[styles.cardName, { color: mutedColor }]}>{card.name}</Text>
        <Text style={[styles.cardNumber, { color }]}>•••• •••• •••• {card.number}</Text>
      </View>
      <View style={styles.cardFooter}>
        <View>
          <Text style={[styles.cardFooterLabel, { color: card.isDark ? '#FFFFFF66' : '#AAAAAA' }]}>{card.type === 'Crédito' ? 'Limite disponível' : 'Saldo'}</Text>
          <Text style={[styles.cardFooterValue, { color }]}>{card.type === 'Crédito' ? card.limit : card.balance}</Text>
        </View>
        <View style={[styles.cardTypeBadge, { borderColor: card.isDark ? '#FFFFFF33' : '#E8E8E8' }]}>
          <Text style={[styles.cardTypeText, { color }]}>{card.type.toUpperCase()}</Text>
        </View>
      </View>
    </RNAnimated.View>
  );
}

export default function CardsScreen() {
  const contentOpacity = useRef(new RNAnimated.Value(0)).current;
  useEffect(() => { RNAnimated.sequence([RNAnimated.delay(600), RNAnimated.timing(contentOpacity, { toValue: 1, duration: 500, useNativeDriver: true })]).start(); }, []);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}><View style={styles.backIcon}><View style={{ transform: [{ rotate: '180deg' }] }}><ChevronRight size={20} color="#000000" /></View></View></TouchableOpacity>
        <Text style={styles.headerTitle}>Meus Cartões</Text>
        <TouchableOpacity style={styles.addButton}><Plus size={20} color="#000000" /></TouchableOpacity>
      </View>
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.scrollContent}>
        <View style={styles.cardsSection}>{CARDS.map((card, i) => <CardComponent key={card.id} card={card} index={i} />)}</View>
        <RNAnimated.View style={[styles.actionsSection, { opacity: contentOpacity }]}>
          <Text style={styles.sectionTitle}>Gerenciamento</Text>
          {[
            { icon: Lock, label: 'Bloquear cartão', desc: 'Bloqueio temporário' },
            { icon: Unlock, label: 'Desbloquear', desc: 'Cartão virtual ativo' },
            { icon: Eye, label: 'Dados do cartão', desc: 'Ver número e CVV' },
            { icon: Settings, label: 'Limites e ajustes', desc: 'Configurar limites' },
            { icon: Snowflake, label: 'Congelar', desc: 'Congelar transações' },
            { icon: QrCode, label: 'Cartão virtual', desc: 'Gerar novo cartão' },
          ].map((item) => (
            <TouchableOpacity key={item.label} style={styles.actionItem}>
              <View style={styles.actionIcon}><item.icon size={20} color="#000000" /></View>
              <View style={styles.actionInfo}><Text style={styles.actionLabel}>{item.label}</Text><Text style={styles.actionDesc}>{item.desc}</Text></View>
              <ChevronRight size={18} color="#CCCCCC" />
            </TouchableOpacity>
          ))}
        </RNAnimated.View>
      </ScrollView>
      <BottomNav activeTab="cards" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FFFFFF' },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 24, paddingTop: 50, paddingBottom: 20 },
  backIcon: { width: 40, height: 40, borderRadius: 20, backgroundColor: '#F5F5F5', alignItems: 'center', justifyContent: 'center' },
  headerTitle: { fontSize: 17, fontWeight: '700', color: '#000000' },
  addButton: { width: 40, height: 40, borderRadius: 20, backgroundColor: '#000000', alignItems: 'center', justifyContent: 'center' },
  scrollContent: { paddingBottom: 100, paddingHorizontal: 24 },
  cardsSection: { gap: 16, marginTop: 8 },
  card: { borderRadius: 20, padding: 20, minHeight: 190, justifyContent: 'space-between', overflow: 'hidden', borderWidth: 1, borderColor: '#E8E8E8' },
  cardPattern: { position: 'absolute', top: -40, right: -40, width: 140, height: 140, borderRadius: 70, borderWidth: 25, borderColor: 'rgba(255,255,255,0.06)' },
  cardPattern2: { position: 'absolute', bottom: -50, left: -50, width: 160, height: 160, borderRadius: 80, borderWidth: 30, borderColor: 'rgba(255,255,255,0.04)' },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  cardChip: { width: 32, height: 24, borderRadius: 5, borderWidth: 1 },
  cardInfo: { marginTop: 12 },
  cardName: { fontSize: 12, fontWeight: '600', letterSpacing: 2, textTransform: 'uppercase', marginBottom: 6 },
  cardNumber: { fontSize: 16, fontWeight: '500', letterSpacing: 3 },
  cardFooter: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-end', marginTop: 12 },
  cardFooterLabel: { fontSize: 10, fontWeight: '500', letterSpacing: 1, textTransform: 'uppercase', marginBottom: 4 },
  cardFooterValue: { fontSize: 16, fontWeight: '700' },
  cardTypeBadge: { paddingHorizontal: 10, paddingVertical: 4, borderRadius: 8, borderWidth: 1 },
  cardTypeText: { fontSize: 10, fontWeight: '700', letterSpacing: 1 },
  actionsSection: { marginTop: 32 },
  sectionTitle: { fontSize: 18, fontWeight: '700', color: '#000000', marginBottom: 16 },
  actionItem: { flexDirection: 'row', alignItems: 'center', paddingVertical: 14, borderBottomWidth: 1, borderBottomColor: '#F0F0F0' },
  actionIcon: { width: 40, height: 40, borderRadius: 12, backgroundColor: '#F5F5F5', alignItems: 'center', justifyContent: 'center', borderWidth: 1, borderColor: '#E8E8E8' },
  actionInfo: { flex: 1, marginLeft: 12 },
  actionLabel: { fontSize: 14, fontWeight: '600', color: '#000000', marginBottom: 2 },
  actionDesc: { fontSize: 12, color: '#888888' },
});
