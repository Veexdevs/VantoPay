import React, { useEffect, useRef, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Switch,
  Animated as RNAnimated,
} from 'react-native';
import { router } from 'expo-router';
import {
  CreditCard,
  Eye,
  Shield,
  Smartphone,
  Bell,
  Fingerprint,
  Moon,
  Globe,
  HelpCircle,
  Settings,
  LogOut,
  ChevronRight,
  Star,
} from 'lucide-react-native';
import { BottomNav } from '../components/BottomNav';
import { Logo } from '../components/Logo';

export default function ProfileScreen() {
  const [notifications, setNotifications] = useState(true);
  const [biometric, setBiometric] = useState(true);
  const [darkMode, setDarkMode] = useState(false);
  const contentOpacity = useRef(new RNAnimated.Value(0)).current;

  useEffect(() => {
    RNAnimated.timing(contentOpacity, {
      toValue: 1,
      duration: 600,
      useNativeDriver: true,
    }).start();
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <View style={styles.backIcon}>
            <ChevronRight size={20} color="#000000" strokeWidth={2} style={{ transform: [{ rotate: '180deg' }] }} />
          </View>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Perfil</Text>
        <TouchableOpacity style={styles.editBtn}>
          <Text style={styles.editText}>Editar</Text>
        </TouchableOpacity>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.scrollContent}>
        {/* Profile Card */}
        <View style={styles.profileCard}>
          <View style={styles.avatarLarge}>
            <Text style={styles.avatarTextLarge}>VP</Text>
          </View>
          <Text style={styles.profileName}>VantoPay User</Text>
          <Text style={styles.profileEmail}>user@vantopay.com</Text>
          <View style={styles.profileBadge}>
            <Star size={14} color="#000000" strokeWidth={2} fill="#000000" />
            <Text style={styles.profileBadgeText}>Premium</Text>
          </View>
        </View>

        <RNAnimated.View style={{ opacity: contentOpacity }}>
          {/* Account Info */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Conta</Text>
            {[
              { icon: CreditCard, label: 'Cartões', desc: '3 cartões ativos' },
              { icon: Eye, label: 'Privacidade', desc: 'Controle de dados' },
              { icon: Shield, label: 'Segurança', desc: 'Senha e autenticação' },
              { icon: Smartphone, label: 'Dispositivos', desc: '2 dispositivos conectados' },
            ].map((item) => (
              <TouchableOpacity key={item.label} style={styles.settingItem}>
                <View style={styles.settingIcon}>
                  <item.icon size={20} color="#000000" strokeWidth={1.8} />
                </View>
                <View style={styles.settingInfo}>
                  <Text style={styles.settingLabel}>{item.label}</Text>
                  <Text style={styles.settingDesc}>{item.desc}</Text>
                </View>
                <ChevronRight size={18} color="#CCCCCC" />
              </TouchableOpacity>
            ))}
          </View>

          {/* Preferences */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Preferências</Text>
            {[
              { icon: Bell, label: 'Notificações', desc: 'Alertas e avisos', isSwitch: true, value: notifications, onChange: setNotifications },
              { icon: Fingerprint, label: 'Biometria', desc: 'Face ID / Digital', isSwitch: true, value: biometric, onChange: setBiometric },
              { icon: Moon, label: 'Modo escuro', desc: 'Tema do aplicativo', isSwitch: true, value: darkMode, onChange: setDarkMode },
              { icon: Globe, label: 'Idioma', desc: 'Português (BR)', isSwitch: false },
            ].map((item) => (
              <TouchableOpacity key={item.label} style={styles.settingItem} activeOpacity={item.isSwitch ? 1 : 0.7}>
                <View style={styles.settingIcon}>
                  <item.icon size={20} color="#000000" strokeWidth={1.8} />
                </View>
                <View style={styles.settingInfo}>
                  <Text style={styles.settingLabel}>{item.label}</Text>
                  <Text style={styles.settingDesc}>{item.desc}</Text>
                </View>
                {item.isSwitch ? (
                  <Switch
                    value={item.value}
                    onValueChange={item.onChange}
                    trackColor={{ false: '#E0E0E0', true: '#000000' }}
                    thumbColor="#FFFFFF"
                  />
                ) : (
                  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                    <Text style={styles.settingValue}>{item.desc}</Text>
                    <ChevronRight size={18} color="#CCCCCC" />
                  </View>
                )}
              </TouchableOpacity>
            ))}
          </View>

          {/* Support */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Suporte</Text>
            {[
              { icon: HelpCircle, label: 'Central de ajuda' },
              { icon: Settings, label: 'Sobre o VantoPay', desc: 'v1.0.0' },
            ].map((item) => (
              <TouchableOpacity key={item.label} style={styles.settingItem}>
                <View style={styles.settingIcon}>
                  <item.icon size={20} color="#000000" strokeWidth={1.8} />
                </View>
                <View style={styles.settingInfo}>
                  <Text style={styles.settingLabel}>{item.label}</Text>
                  {item.desc && <Text style={styles.settingDesc}>{item.desc}</Text>}
                </View>
                <ChevronRight size={18} color="#CCCCCC" />
              </TouchableOpacity>
            ))}
          </View>

          {/* Logout */}
          <View style={styles.logoutSection}>
            <TouchableOpacity style={styles.logoutBtn}>
              <LogOut size={20} color="#000000" strokeWidth={1.8} />
              <Text style={styles.logoutText}>Sair da conta</Text>
            </TouchableOpacity>
          </View>

          {/* Branding */}
          <View style={styles.branding}>
            <Logo size={32} />
            <Text style={styles.brandText}>VantoPay v1.0.0</Text>
          </View>
        </RNAnimated.View>
      </ScrollView>

      <BottomNav activeTab="profile" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FFFFFF' },
  header: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    paddingHorizontal: 24, paddingTop: 50, paddingBottom: 16,
  },
  backIcon: {
    width: 40, height: 40, borderRadius: 20, backgroundColor: '#F5F5F5',
    alignItems: 'center', justifyContent: 'center',
  },
  headerTitle: { fontSize: 17, fontWeight: '700', color: '#000000' },
  editBtn: {
    width: 56, height: 32, borderRadius: 16, backgroundColor: '#000000',
    alignItems: 'center', justifyContent: 'center',
  },
  editText: { color: '#FFFFFF', fontSize: 12, fontWeight: '700' },
  scrollContent: { paddingBottom: 100, paddingHorizontal: 24 },
  profileCard: { alignItems: 'center', paddingVertical: 20 },
  avatarLarge: {
    width: 80, height: 80, borderRadius: 40, backgroundColor: '#000000',
    alignItems: 'center', justifyContent: 'center', marginBottom: 12,
  },
  avatarTextLarge: { color: '#FFFFFF', fontSize: 28, fontWeight: '800', letterSpacing: 2 },
  profileName: { fontSize: 22, fontWeight: '800', color: '#000000', marginBottom: 4 },
  profileEmail: { fontSize: 14, color: '#888888', marginBottom: 12 },
  profileBadge: {
    flexDirection: 'row', alignItems: 'center', gap: 6,
    backgroundColor: '#F0F0F0', paddingHorizontal: 14, paddingVertical: 6, borderRadius: 20,
  },
  profileBadgeText: { fontSize: 12, fontWeight: '700', color: '#000000' },
  section: { marginTop: 24 },
  sectionTitle: {
    fontSize: 13, fontWeight: '700', color: '#888888',
    textTransform: 'uppercase', letterSpacing: 1.5, marginBottom: 12,
  },
  settingItem: {
    flexDirection: 'row', alignItems: 'center', paddingVertical: 14,
    borderBottomWidth: 1, borderBottomColor: '#F0F0F0',
  },
  settingIcon: {
    width: 40, height: 40, borderRadius: 12, backgroundColor: '#F5F5F5',
    alignItems: 'center', justifyContent: 'center', borderWidth: 1, borderColor: '#E8E8E8',
  },
  settingInfo: { flex: 1, marginLeft: 12 },
  settingLabel: { fontSize: 14, fontWeight: '600', color: '#000000', marginBottom: 2 },
  settingDesc: { fontSize: 12, color: '#888888' },
  settingValue: { fontSize: 12, color: '#666666', marginRight: 4 },
  logoutSection: { marginTop: 32 },
  logoutBtn: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8,
    paddingVertical: 16, borderRadius: 16, backgroundColor: '#F5F5F5',
    borderWidth: 1, borderColor: '#E8E8E8',
  },
  logoutText: { fontSize: 15, fontWeight: '700', color: '#000000' },
  branding: { alignItems: 'center', marginTop: 32, gap: 8 },
  brandText: { fontSize: 12, color: '#CCCCCC', fontWeight: '500' },
});
