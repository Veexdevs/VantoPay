import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Animated as RNAnimated,
} from 'react-native';
import { router } from 'expo-router';
import {
  Search,
  ChevronRight,
  Download,
  TrendingUp,
  TrendingDown,
  Star,
  Music,
  Briefcase,
  UtensilsCrossed,
  Play,
  ArrowDown,
  Car,
  ShoppingBag,
  Heart,
} from 'lucide-react-native';
import { BottomNav } from '../components/BottomNav';

const ALL_TRANSACTIONS = [
  { id: '1', name: 'Spotify Premium', amount: -21.90, type: 'expense' as const, category: 'Entretenimento', time: 'Hoje 14:32', icon: 'music' },
  { id: '2', name: 'Salário', amount: 8500.00, type: 'income' as const, category: 'Receita', time: 'Hoje 09:00', icon: 'briefcase' },
  { id: '3', name: 'iFood', amount: -45.80, type: 'expense' as const, category: 'Alimentação', time: 'Ontem 20:15', icon: 'utensils' },
  { id: '4', name: 'Netflix', amount: -39.90, type: 'expense' as const, category: 'Entretenimento', time: 'Ontem 10:00', icon: 'play' },
  { id: '5', name: 'Transferência recebida', amount: 250.00, type: 'income' as const, category: 'Transferência', time: 'Seg 11:20', icon: 'arrow-down' },
  { id: '6', name: 'Uber', amount: -28.50, type: 'expense' as const, category: 'Transporte', time: 'Seg 08:45', icon: 'car' },
  { id: '7', name: 'Amazon', amount: -189.90, type: 'expense' as const, category: 'Compras', time: 'Dom 16:30', icon: 'shopping' },
  { id: '8', name: 'Freelance', amount: 1200.00, type: 'income' as const, category: 'Receita', time: 'Sáb 14:00', icon: 'briefcase' },
  { id: '9', name: 'Padaria', amount: -12.50, type: 'expense' as const, category: 'Alimentação', time: 'Sáb 07:30', icon: 'utensils' },
  { id: '10', name: 'Academia', amount: -99.90, type: 'expense' as const, category: 'Saúde', time: 'Sex 18:00', icon: 'heart' },
];

const FILTERS = ['Todas', 'Entradas', 'Saídas', 'PIX', 'Cartão'];

const ICON_MAP: Record<string, any> = {
  music: Music,
  briefcase: Briefcase,
  utensils: UtensilsCrossed,
  play: Play,
  'arrow-down': ArrowDown,
  car: Car,
  shopping: ShoppingBag,
  heart: Heart,
};

export default function TransactionsScreen() {
  const [activeFilter, setActiveFilter] = useState('Todas');
  const listOpacity = useRef(new RNAnimated.Value(0)).current;

  useEffect(() => {
    RNAnimated.timing(listOpacity, {
      toValue: 1,
      duration: 500,
      useNativeDriver: true,
    }).start();
  }, []);

  const filtered = ALL_TRANSACTIONS.filter(tx => {
    if (activeFilter === 'Entradas') return tx.type === 'income';
    if (activeFilter === 'Saídas') return tx.type === 'expense';
    if (activeFilter === 'PIX') return tx.category === 'Transferência';
    if (activeFilter === 'Cartão') return ['Entretenimento', 'Alimentação', 'Compras', 'Transporte', 'Saúde'].includes(tx.category);
    return true;
  });

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <View style={styles.backIcon}>
            <ChevronRight size={20} color="#000000" strokeWidth={2} style={{ transform: [{ rotate: '180deg' }] }} />
          </View>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Transações</Text>
        <TouchableOpacity style={styles.actionBtn}>
          <Download size={20} color="#000000" strokeWidth={2} />
        </TouchableOpacity>
      </View>

      {/* Summary Cards */}
      <View style={styles.summarySection}>
        <View style={styles.summaryCard}>
          <View style={styles.summaryIcon}>
            <TrendingUp size={20} color="#000000" strokeWidth={1.8} />
          </View>
          <View>
            <Text style={styles.summaryLabel}>Entradas</Text>
            <Text style={styles.summaryValue}>+R$ 9.950,00</Text>
          </View>
        </View>
        <View style={styles.summaryCard}>
          <View style={[styles.summaryIcon, { backgroundColor: '#F0F0F0' }]}>
            <TrendingDown size={20} color="#000000" strokeWidth={1.8} />
          </View>
          <View>
            <Text style={styles.summaryLabel}>Saídas</Text>
            <Text style={styles.summaryValue}>-R$ 438,50</Text>
          </View>
        </View>
      </View>

      {/* Filters */}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.filtersContainer}
      >
        {FILTERS.map((filter) => (
          <TouchableOpacity
            key={filter}
            style={[styles.filterBtn, activeFilter === filter && styles.filterBtnActive]}
            onPress={() => setActiveFilter(filter)}
          >
            <Text style={[styles.filterText, activeFilter === filter && styles.filterTextActive]}>
              {filter}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      {/* Search */}
      <View style={styles.searchContainer}>
        <View style={styles.searchInput}>
          <Search size={18} color="#AAAAAA" strokeWidth={2} />
          <TextInput
            style={styles.searchText}
            placeholder="Buscar transações..."
            placeholderTextColor="#CCCCCC"
          />
        </View>
      </View>

      {/* Transaction List */}
      <RNAnimated.View style={[{ opacity: listOpacity }, { flex: 1 }]}>
        <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.scrollContent}>
          <Text style={styles.resultCount}>{filtered.length} transações</Text>
          {filtered.map((tx) => {
            const IconComp = ICON_MAP[tx.icon] || Star;
            return (
              <View key={tx.id} style={styles.txRow}>
                <View style={[styles.txIcon, { backgroundColor: tx.type === 'income' ? '#F0F0F0' : '#F8F8F8' }]}>
                  <IconComp size={18} color="#000000" strokeWidth={1.8} />
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
            );
          })}
        </ScrollView>
      </RNAnimated.View>

      <BottomNav activeTab="transactions" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 24,
    paddingTop: 50,
    paddingBottom: 16,
  },
  backIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#F5F5F5',
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: '#000000',
  },
  actionBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#F5F5F5',
    alignItems: 'center',
    justifyContent: 'center',
  },
  summarySection: {
    flexDirection: 'row',
    gap: 12,
    paddingHorizontal: 24,
    marginBottom: 16,
  },
  summaryCard: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: '#F8F8F8',
    borderRadius: 16,
    padding: 14,
    borderWidth: 1,
    borderColor: '#EEEEEE',
  },
  summaryIcon: {
    width: 38,
    height: 38,
    borderRadius: 12,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#E8E8E8',
  },
  summaryLabel: {
    fontSize: 11,
    color: '#888888',
    fontWeight: '500',
  },
  summaryValue: {
    fontSize: 15,
    fontWeight: '800',
    color: '#000000',
  },
  filtersContainer: {
    paddingHorizontal: 24,
    gap: 8,
    marginBottom: 12,
  },
  filterBtn: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#F5F5F5',
    borderWidth: 1,
    borderColor: '#E8E8E8',
    marginRight: 8,
  },
  filterBtnActive: {
    backgroundColor: '#000000',
    borderColor: '#000000',
  },
  filterText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#666666',
  },
  filterTextActive: {
    color: '#FFFFFF',
  },
  searchContainer: {
    paddingHorizontal: 24,
    marginBottom: 16,
  },
  searchInput: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F8F8F8',
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderWidth: 1,
    borderColor: '#EEEEEE',
    gap: 10,
  },
  searchText: {
    flex: 1,
    fontSize: 14,
    color: '#000000',
  },
  scrollContent: {
    paddingHorizontal: 24,
    paddingBottom: 100,
  },
  resultCount: {
    fontSize: 12,
    fontWeight: '600',
    color: '#AAAAAA',
    marginBottom: 8,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  txRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F0F0F0',
  },
  txIcon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  txInfo: {
    flex: 1,
    marginLeft: 12,
  },
  txName: {
    fontSize: 14,
    fontWeight: '600',
    color: '#000000',
    marginBottom: 2,
  },
  txCat: {
    fontSize: 12,
    color: '#888888',
    fontWeight: '400',
  },
  txAmount: {
    alignItems: 'flex-end',
  },
  txValue: {
    fontSize: 14,
    fontWeight: '700',
  },
  txTime: {
    fontSize: 11,
    color: '#AAAAAA',
    marginTop: 2,
  },
});
