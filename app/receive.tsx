import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Animated as RNAnimated,
  Easing,
} from 'react-native';
import { router } from 'expo-router';
import {
  ChevronRight,
  Copy,
  Share2,
  Check,
  Zap,
  Banknote,
  CreditCard,
} from 'lucide-react-native';
import { Logo } from '../components/Logo';

export default function ReceiveScreen() {
  const [copied, setCopied] = useState(false);
  const qrOpacity = useRef(new RNAnimated.Value(0)).current;
  const qrScale = useRef(new RNAnimated.Value(0.8)).current;
  const contentOpacity = useRef(new RNAnimated.Value(0)).current;

  useEffect(() => {
    RNAnimated.parallel([
      RNAnimated.sequence([
        RNAnimated.delay(300),
        RNAnimated.timing(qrOpacity, {
          toValue: 1,
          duration: 500,
          useNativeDriver: true,
        }),
      ]),
      RNAnimated.sequence([
        RNAnimated.delay(300),
        RNAnimated.spring(qrScale, {
          toValue: 1,
          friction: 5,
          tension: 60,
          useNativeDriver: true,
        }),
      ]),
      RNAnimated.sequence([
        RNAnimated.delay(500),
        RNAnimated.timing(contentOpacity, {
          toValue: 1,
          duration: 500,
          useNativeDriver: true,
        }),
      ]),
    ]).start();
  }, []);

  const handleCopy = () => {
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <View style={styles.backIcon}>
            <ChevronRight size={20} color="#000000" strokeWidth={2} style={{ transform: [{ rotate: '180deg' }] }} />
          </View>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Receber</Text>
        <View style={{ width: 40 }} />
      </View>

      <View style={styles.content}>
        {/* QR Code */}
        <View style={styles.qrSection}>
          <RNAnimated.View
            style={[
              styles.qrContainer,
              { opacity: qrOpacity, transform: [{ scale: qrScale }] },
            ]}
          >
            <View style={styles.qrCode}>
              <View style={styles.qrPattern}>
                {Array.from({ length: 9 }).map((_, row) => (
                  <View key={row} style={styles.qrRow}>
                    {Array.from({ length: 9 }).map((_, col) => {
                      const isCorner = (row < 3 && col < 3) || (row < 3 && col > 5) || (row > 5 && col < 3);
                      const isFilled = (row * col + row + col) % 3 !== 0;
                      return (
                        <View
                          key={col}
                          style={[
                            styles.qrCell,
                            isFilled && !isCorner && styles.qrCellFilled,
                            isCorner && styles.qrCorner,
                          ]}
                        />
                      );
                    })}
                  </View>
                ))}
              </View>
              <View style={styles.qrLogo}>
                <Logo size={40} />
              </View>
            </View>
          </RNAnimated.View>

          <RNAnimated.Text
            style={[styles.qrLabel, { opacity: qrOpacity }]}
          >
            Escaneie o QR Code para receber
          </RNAnimated.Text>
        </View>

        {/* PIX Key */}
        <RNAnimated.View style={[styles.pixKeySection, { opacity: contentOpacity }]}>
          <Text style={styles.pixLabel}>Chave PIX</Text>
          <View style={styles.pixKeyContainer}>
            <Text style={styles.pixKeyValue}>user@vantopay.com</Text>
            <TouchableOpacity style={styles.copyBtn} onPress={handleCopy}>
              {copied ? (
                <Check size={18} color="#000000" strokeWidth={2} />
              ) : (
                <Copy size={18} color="#000000" strokeWidth={2} />
              )}
            </TouchableOpacity>
          </View>
          {copied && <Text style={styles.copiedText}>Chave copiada!</Text>}
        </RNAnimated.View>

        {/* Receive Methods */}
        <RNAnimated.View style={[styles.methodsSection, { opacity: contentOpacity }]}>
          <Text style={styles.sectionTitle}>Receber via</Text>
          {[
            { icon: Zap, label: 'PIX', desc: 'Instantâneo' },
            { icon: Banknote, label: 'TED', desc: '1-2 dias úteis' },
            { icon: CreditCard, label: 'Cartão', desc: 'Transferência' },
          ].map((method) => (
            <TouchableOpacity key={method.label} style={styles.methodItem}>
              <View style={styles.methodIcon}>
                <method.icon size={20} color="#000000" strokeWidth={1.8} />
              </View>
              <View style={styles.methodInfo}>
                <Text style={styles.methodLabel}>{method.label}</Text>
                <Text style={styles.methodDesc}>{method.desc}</Text>
              </View>
              <ChevronRight size={18} color="#CCCCCC" />
            </TouchableOpacity>
          ))}
        </RNAnimated.View>
      </View>

      <View style={styles.bottomSection}>
        <TouchableOpacity style={styles.shareBtn}>
          <Share2 size={20} color="#000000" strokeWidth={2} />
          <Text style={styles.shareBtnText}>Compartilhar chave</Text>
        </TouchableOpacity>
      </View>
    </View>
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
  content: { flex: 1, paddingHorizontal: 24, alignItems: 'center' },
  qrSection: { alignItems: 'center', marginBottom: 32 },
  qrContainer: {
    width: 220, height: 220, borderRadius: 24, backgroundColor: '#000000',
    padding: 20, alignItems: 'center', justifyContent: 'center',
  },
  qrCode: {
    width: '100%', height: '100%', backgroundColor: '#FFFFFF',
    borderRadius: 8, alignItems: 'center', justifyContent: 'center', position: 'relative',
  },
  qrPattern: { gap: 0 },
  qrRow: { flexDirection: 'row' },
  qrCell: { width: 18, height: 18, backgroundColor: '#FFFFFF' },
  qrCellFilled: { backgroundColor: '#000000' },
  qrCorner: { backgroundColor: '#000000' },
  qrLogo: { position: 'absolute', backgroundColor: '#FFFFFF', borderRadius: 12, padding: 4 },
  qrLabel: { marginTop: 16, fontSize: 14, color: '#888888', fontWeight: '500' },
  pixKeySection: { width: '100%', marginBottom: 28 },
  pixLabel: {
    fontSize: 13, fontWeight: '700', color: '#888888',
    textTransform: 'uppercase', letterSpacing: 1.5, marginBottom: 8,
  },
  pixKeyContainer: {
    flexDirection: 'row', alignItems: 'center', backgroundColor: '#F5F5F5',
    borderRadius: 14, padding: 14, borderWidth: 1, borderColor: '#E8E8E8', gap: 12,
  },
  pixKeyValue: { flex: 1, fontSize: 15, fontWeight: '600', color: '#000000' },
  copyBtn: {
    width: 36, height: 36, borderRadius: 10, backgroundColor: '#000000',
    alignItems: 'center', justifyContent: 'center',
  },
  copiedText: { fontSize: 12, color: '#000000', fontWeight: '600', marginTop: 6 },
  sectionTitle: {
    fontSize: 13, fontWeight: '700', color: '#888888',
    textTransform: 'uppercase', letterSpacing: 1.5, marginBottom: 12, alignSelf: 'flex-start',
  },
  methodsSection: { width: '100%' },
  methodItem: {
    flexDirection: 'row', alignItems: 'center', paddingVertical: 14,
    borderBottomWidth: 1, borderBottomColor: '#F0F0F0', gap: 12,
  },
  methodIcon: {
    width: 40, height: 40, borderRadius: 12, backgroundColor: '#F5F5F5',
    alignItems: 'center', justifyContent: 'center', borderWidth: 1, borderColor: '#E8E8E8',
  },
  methodInfo: { flex: 1 },
  methodLabel: { fontSize: 14, fontWeight: '600', color: '#000000' },
  methodDesc: { fontSize: 12, color: '#888888' },
  bottomSection: { paddingHorizontal: 24, paddingBottom: 40, alignItems: 'center' },
  shareBtn: {
    flexDirection: 'row', alignItems: 'center', gap: 8,
    backgroundColor: '#000000', paddingHorizontal: 32, paddingVertical: 16, borderRadius: 16,
  },
  shareBtnText: { color: '#FFFFFF', fontSize: 15, fontWeight: '700' },
});
