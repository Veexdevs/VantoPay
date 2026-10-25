import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

interface TransactionProps {
  transaction: {
    id: string;
    name: string;
    amount: number;
    type: 'income' | 'expense';
    category: string;
    time: string;
    icon: string;
  };
}

export function TransactionItem({ transaction }: TransactionProps) {
  const isIncome = transaction.type === 'income';

  return (
    <View style={styles.container}>
      <View style={[styles.iconContainer, { backgroundColor: isIncome ? '#F0F0F0' : '#F8F8F8' }]}>
        {getTransactionIcon(transaction.icon, isIncome)}
      </View>
      <View style={styles.info}>
        <Text style={styles.name}>{transaction.name}</Text>
        <Text style={styles.category}>{transaction.category}</Text>
      </View>
      <View style={styles.amountSection}>
        <Text style={[styles.amount, { color: isIncome ? '#000000' : '#666666' }]}>
          {isIncome ? '+' : '-'} R$ {Math.abs(transaction.amount).toFixed(2)}
        </Text>
        <Text style={styles.time}>{transaction.time}</Text>
      </View>
    </View>
  );
}

function getTransactionIcon(icon: string, isIncome: boolean) {
  const { Music, Briefcase, Utensils, Play, ArrowDown, Car } = require('lucide-react-native');
  
  const icons: Record<string, React.ReactNode> = {
    music: <Music size={18} color="#000000" strokeWidth={1.8} />,
    briefcase: <Briefcase size={18} color="#000000" strokeWidth={1.8} />,
    utensils: <Utensils size={18} color="#000000" strokeWidth={1.8} />,
    play: <Play size={18} color="#000000" strokeWidth={1.8} />,
    'arrow-down': <ArrowDown size={18} color="#000000" strokeWidth={1.8} />,
    car: <Car size={18} color="#000000" strokeWidth={1.8} />,
  };

  return icons[icon] || icons.music;
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F0F0F0',
  },
  iconContainer: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  info: {
    flex: 1,
    marginLeft: 12,
  },
  name: {
    fontSize: 14,
    fontWeight: '600',
    color: '#000000',
    marginBottom: 2,
  },
  category: {
    fontSize: 12,
    color: '#888888',
    fontWeight: '400',
  },
  amountSection: {
    alignItems: 'flex-end',
  },
  amount: {
    fontSize: 14,
    fontWeight: '700',
  },
  time: {
    fontSize: 11,
    color: '#AAAAAA',
    marginTop: 2,
  },
});
