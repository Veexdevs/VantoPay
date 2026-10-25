import React, { useState, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  Animated as RNAnimated,
} from 'react-native';
import { router } from 'expo-router';
import {
  ChevronRight,
  User,
  ArrowUpRight,
  Check,
  Zap,
  Clock,
} from 'lucide-react-native';

const CONTACTS = [
  { name: 'Ana Silva', key: 'ana@email.com', initials: 'AS' },
  { name: 'Carlos M.', key: '123.456.789-00', initials: 'CM' },
  { name: 'Julia R.', key: '98765432100', initials: 'JR' },
  { name: 'Pedro Santos', key: 'pedro@email.com', initials: 'PS' },
];

export default function SendScreen() {
  const [amount, setAmount] = useState('');
  const [selectedContact, setSelectedContact] = useState<string | null>(null);
  const [sent, setSent] = useState(false);
  const successOpacity = useRef(new RNAnimated.Value(0)).current;
  const successScale = useRef(new RNAnimated.Value(0.5)).current;

  const handleSend = () => {
    RNAnimated.parallel([
      RNAnimated.timing(successOpacity, {
        toValue: 1,
        duration: 400,
        useNativeDriver: true,
      }),
      RNAnimated.spring(successScale, {
        toValue: 1,
        friction: 5,
        tension: 60,
        useNativeDriver: true,
      }),
    ]).start(() => {
      setSent(true);
    });
  };

  if (sent) {
    return (
      <View style={styles.container}>
        <RNAnimated.View style={[styles.successContainer, { opacity: successOpacity }]}>
          <RNAnimated.View style={[styles.successIcon, { transform: [{ scale: successScale }] }]}>
            <View style={styles.successCircle}>
              <Check size={48} color="#000000" strokeWidth={2} />
            </View>
          </RNAnimated.View>
          <Text style={styles.successTitle}>Enviado com sucesso!</Text>
          <Text style={styles.successAmount}>R$ {amount || '0,00'}</Text>
          <View style={styles.successDetail}>
            <Text style={styles.successDetailText}>Transferência PIX instantânea</Text>
          </View>
          <TouchableOpacity
            style={styles.doneBtn}
            onPress={() => router.replace('/home')}
          >
            <Text style={styles.doneBtnText}>Voltar ao início</Text>
          </TouchableOpacity>
        </RNAnimated.View>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <View style={styles.backIcon}>
            <ChevronRight size={20} color="#000000" strokeWidth={2} style={{ transform: [{ rotate: '180deg' }] }} />
          </View>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Enviar</Text>
        <View style={{ width: 40 }} />
      </View>

      <View style={styles.content}>
        {/* Contact selector */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Para</Text>
          <View style={styles.contactsRow}>
            {CONTACTS.map((contact) => (
              <TouchableOpacity
                key={contact.key}
                style={[styles.contactAvatar, selectedContact === contact.key && styles.contactAvatarActive]}
                onPress={() => setSelectedContact(contact.key)}
              >
                <Text style={[styles.contactInitials, selectedContact === contact.key && styles.contactInitialsActive]}>
                  {contact.initials}
                </Text>
              </TouchableOpacity>
            ))}
            <TouchableOpacity style={styles.addContact}>
              <User size={20} color="#000000" strokeWidth={1.8} />
            </TouchableOpacity>
          </View>
        </View>

        {/* Amount input */}
        <View style={styles.amountSection}>
          <Text style={styles.amountLabel}>Valor</Text>
          <View style={styles.amountInputWrapper}>
            <Text style={styles.currencySymbol}>R$</Text>
            <TextInput
              style={styles.amountInput}
              value={amount}
              onChangeText={setAmount}
              placeholder="0,00"
              placeholderTextColor="#CCCCCC"
              keyboardType="decimal-pad"
              autoFocus
            />
          </View>
        </View>

        {/* Payment method */}
        <View style={styles.paymentSection}>
          <Text style={styles.sectionTitle}>Método</Text>
          {[
            { icon: Zap, label: 'PIX', desc: 'Instantâneo', active: true },
            { icon: ArrowUpRight, label: 'TED', desc: '1-2 dias úteis', active: false },
            { icon: Clock, label: 'DOC', desc: 'Próximo dia', active: false },
          ].map((method) => (
            <TouchableOpacity
              key={method.label}
              style={[styles.methodItem, method.active && styles.methodItemActive]}
            >
              <method.icon size={20} color="#000000" strokeWidth={1.8} />
              <View style={styles.methodInfo}>
                <Text style={styles.methodLabel}>{method.label}</Text>
                <Text style={styles.methodDesc}>{method.desc}</Text>
              </View>
              {method.active && (
                <View style={styles.methodCheck}>
                  <Check size={14} color="#FFFFFF" strokeWidth={2.5} />
                </View>
              )}
            </TouchableOpacity>
          ))}
        </View>
      </View>

      <View style={styles.bottomSection}>
        <TouchableOpacity
          style={styles.sendBtn}
          onPress={handleSend}
          disabled={!amount || !selectedContact}
        >
          <View style={[styles.sendBtnInner, !amount || !selectedContact ? styles.sendBtnDisabled : null]}>
            <Text style={styles.sendBtnText}>Enviar agora</Text>
          </View>
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FFFFFF' },
  header: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    paddingHorizontal: 24, paddingTop: 50, paddingBottom: 20,
  },
  backIcon: {
    width: 40, height: 40, borderRadius: 20, backgroundColor: '#F5F5F5',
    alignItems: 'center', justifyContent: 'center',
  },
  headerTitle: { fontSize: 17, fontWeight: '700', color: '#000000' },
  content: { flex: 1, paddingHorizontal: 24 },
  section: { marginBottom: 24 },
  sectionTitle: {
    fontSize: 13, fontWeight: '700', color: '#888888',
    textTransform: 'uppercase', letterSpacing: 1.5, marginBottom: 12,
  },
  contactsRow: { flexDirection: 'row', gap: 12, alignItems: 'center' },
  contactAvatar: {
    width: 48, height: 48, borderRadius: 24, backgroundColor: '#F5F5F5',
    alignItems: 'center', justifyContent: 'center', borderWidth: 2, borderColor: 'transparent',
  },
  contactAvatarActive: { backgroundColor: '#000000', borderColor: '#000000' },
  contactInitials: { fontSize: 14, fontWeight: '700', color: '#000000' },
  contactInitialsActive: { color: '#FFFFFF' },
  addContact: {
    width: 48, height: 48, borderRadius: 24, borderWidth: 2,
    borderColor: '#E8E8E8', borderStyle: 'dashed',
    alignItems: 'center', justifyContent: 'center',
  },
  amountSection: { marginBottom: 24 },
  amountLabel: {
    fontSize: 13, fontWeight: '700', color: '#888888',
    textTransform: 'uppercase', letterSpacing: 1.5, marginBottom: 8,
  },
  amountInputWrapper: {
    flexDirection: 'row', alignItems: 'center',
    borderBottomWidth: 2, borderBottomColor: '#000000', paddingBottom: 8, gap: 4,
  },
  currencySymbol: { fontSize: 20, fontWeight: '600', color: '#888888' },
  amountInput: { flex: 1, fontSize: 36, fontWeight: '800', color: '#000000' },
  paymentSection: { marginBottom: 24 },
  methodItem: {
    flexDirection: 'row', alignItems: 'center', paddingVertical: 14,
    borderBottomWidth: 1, borderBottomColor: '#F0F0F0', gap: 12,
  },
  methodItemActive: {
    backgroundColor: '#F8F8F8', borderRadius: 12,
    paddingHorizontal: 12, borderBottomColor: '#F0F0F0',
  },
  methodInfo: { flex: 1 },
  methodLabel: { fontSize: 14, fontWeight: '600', color: '#000000' },
  methodDesc: { fontSize: 12, color: '#888888' },
  methodCheck: {
    width: 24, height: 24, borderRadius: 12,
    backgroundColor: '#000000', alignItems: 'center', justifyContent: 'center',
  },
  bottomSection: { paddingHorizontal: 24, paddingBottom: 40 },
  sendBtn: { width: '100%' },
  sendBtnInner: {
    backgroundColor: '#000000', paddingVertical: 18,
    borderRadius: 16, alignItems: 'center',
  },
  sendBtnDisabled: { backgroundColor: '#E0E0E0' },
  sendBtnText: { color: '#FFFFFF', fontSize: 16, fontWeight: '700' },
  // Success
  successContainer: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 24 },
  successIcon: { marginBottom: 24 },
  successCircle: {
    width: 100, height: 100, borderRadius: 50, backgroundColor: '#F0F0F0',
    alignItems: 'center', justifyContent: 'center', borderWidth: 2, borderColor: '#000000',
  },
  successTitle: { fontSize: 24, fontWeight: '800', color: '#000000', marginBottom: 8 },
  successAmount: { fontSize: 36, fontWeight: '800', color: '#000000', marginBottom: 16 },
  successDetail: { marginBottom: 40 },
  successDetailText: { fontSize: 14, color: '#888888' },
  doneBtn: {
    backgroundColor: '#000000', paddingHorizontal: 40,
    paddingVertical: 16, borderRadius: 16,
  },
  doneBtnText: { color: '#FFFFFF', fontSize: 16, fontWeight: '700' },
});
