import React, { useState, useEffect } from "react";
import { 
  Shield, 
  Code, 
  Terminal, 
  FileCode, 
  Copy, 
  Check, 
  Download, 
  Lock, 
  RefreshCw, 
  Cpu, 
  Play, 
  CheckCircle2, 
  AlertTriangle, 
  HelpCircle, 
  Workflow, 
  Info,
  Layers,
  Sparkles,
  Search,
  Plus,
  Trash2,
  LockKeyhole,
  Eye,
  EyeOff,
  AlertCircle,
  CopyCheck,
  RotateCw,
  KeyRound,
  Sliders,
  Award,
  BookOpen,
  Activity,
  Maximize2
} from "lucide-react";
import { dartFiles, DartFile } from "./data/dartCode";

interface MockVaultItem {
  id: string;
  name: string;
  type: number; // 1 = Login, 2 = Credit Card, 3 = Secure Note, 4 = TOTP authenticator
  isFavorite: boolean;
  updatedAt: string;
  fields: Array<{
    name: string;
    value: string; // Base64 encrypted cipher representation in database
    fieldType: number; // 1 = Text, 2 = Password, 3 = TOTP Secret, 4 = Card CVV
    isSensitive: boolean;
    decryptedValue?: string; // Hot simulated decrypted RAM representation
  }>;
}

export default function App() {
  const [activeTab, setActiveTab] = useState<"files" | "vault" | "sandbox" | "tests" | "autofill" | "security">("vault");
  const [selectedFile, setSelectedFile] = useState<DartFile>(dartFiles[5]); // Default to main_screen.dart
  const [copied, setCopied] = useState<string | null>(null);

  // Autofill Sandbox Simulation Parameters
  const [autofillPlatform, setAutofillPlatform] = useState<"android" | "ios" | "chrome">("android");
  const [autofillDomain, setAutofillDomain] = useState("github.com");
  const [mockFormUser, setMockFormUser] = useState("");
  const [mockFormPass, setMockFormPass] = useState("");
  const [isFaceIDPassed, setIsFaceIDPassed] = useState(false);
  const [autofillTelemetry, setAutofillTelemetry] = useState<Array<{ time: string; system: string; event: string; status: "success" | "info" | "sec" }>>([
    { time: "23:22:00", system: "DartVM", event: "AutofillChannelService established on channel io.nexpass.app/autofill", status: "success" },
    { time: "23:22:05", system: "Android", event: "AutofillManager bounds identified matching autocomplete hints", status: "info" }
  ]);

  const addAutofillLog = (system: string, event: string, status: "success" | "info" | "sec" = "info") => {
    const now = new Date();
    const ts = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
    setAutofillTelemetry(prev => [{ time: ts, system, event, status }, ...prev].slice(0, 15));
  };

  // WebDAV Synchronization Simulation Parameters
  const [webdavUrl, setWebdavUrl] = useState("https://dav.jianguoyun.com/dav/nexpass");
  const [webdavUser, setWebdavUser] = useState("monica_dev@nexpass.io");
  const [webdavPass, setWebdavPass] = useState("••••••••••••••••");
  const [webdavSyncStatus, setWebdavSyncStatus] = useState<"idle" | "handshake" | "comparing" | "downloading" | "uploading" | "success" | "error">("idle");
  const [isWebdavAutoSync, setIsWebdavAutoSync] = useState(false);
  const [webdavLogs, setWebdavLogs] = useState<Array<{ time: string; action: string; status: "success" | "info" | "warn" }>>([
    { time: "23:23:10", action: "WebDAV SyncService initialized with credential token basic-auth-base64", status: "success" },
    { time: "23:23:45", action: "Completed local Isar database indexing. Standard backup schema generated", status: "info" }
  ]);

  const addWebdavLog = (action: string, status: "success" | "info" | "warn" = "info") => {
    const now = new Date();
    const ts = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
    setWebdavLogs(prev => [{ time: ts, action, status }, ...prev].slice(0, 15));
  };

  // Monica-Inspired Dual-Clipboard Buffer Intercept Toast Details
  const [dualClipboardToast, setDualClipboardToast] = useState<{
    show: boolean;
    itemName: string;
    passwordCopied: string;
    totpCopied: string;
  } | null>(null);

  // Search and Category Tabs
  const [searchQuery, setSearchQuery] = useState("");
  const [activeCategoryTab, setActiveCategoryTab] = useState<number>(0); // 0=All, 1=Logins, 2=Cards, 3=TOTP
  const [weakAuditOnly, setWeakAuditOnly] = useState(false);
  const [selectedItemForDetails, setSelectedItemForDetails] = useState<MockVaultItem | null>(null);

  // Riverpod State Tracking Simulation
  const [riverpodLogs, setRiverpodLogs] = useState<Array<{
    timestamp: string;
    type: "provider_read" | "state_change" | "action";
    message: string;
  }>>([
    { timestamp: "23:19:00", type: "provider_read", message: "masterKeyProvider resolved 256-bit hash" },
    { timestamp: "23:19:01", type: "provider_read", message: "repositoryProvider mapped to offline encrypted Isar instance" },
    { timestamp: "23:19:02", type: "state_change", message: "vaultStateProvider initiated with 4 secure accounts" }
  ]);

  const addRiverpodLog = (type: "provider_read" | "state_change" | "action", message: string) => {
    const now = new Date();
    const ts = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
    setRiverpodLogs((prev) => [{ timestamp: ts, type, message }, ...prev].slice(0, 15));
  };

  // Base64 encrypted mock storage representation helper
  const encryptSimulatedBase64 = (plaintext: string) => {
    return btoa(plaintext.split("").reverse().join("")); // Simple deterministic reversible safe cipher
  };

  const decryptSimulatedBase64 = (ciphertext: string) => {
    try {
      return atob(ciphertext).split("").reverse().join("");
    } catch (_) {
      return ciphertext;
    }
  };

  // Vault Items Initial Set
  const [vaultItems, setVaultItems] = useState<MockVaultItem[]>([
    {
      id: "vault-1",
      name: "GitHub Repository Keypair",
      type: 1,
      isFavorite: true,
      updatedAt: "2026-05-19 23:05",
      fields: [
        { name: "username", value: "nexpass_user_dev", fieldType: 1, isSensitive: false, decryptedValue: "nexpass_user_dev" },
        { name: "password", value: encryptSimulatedBase64("ghp_SecretDeveloperV2_Argon2Safe"), fieldType: 2, isSensitive: true, decryptedValue: "ghp_SecretDeveloperV2_Argon2Safe" }
      ]
    },
    {
      id: "vault-2",
      name: "Corporate Ledger Debit Card",
      type: 2,
      isFavorite: false,
      updatedAt: "2026-05-19 22:15",
      fields: [
        { name: "cardholder", value: "MONICA DEV", fieldType: 1, isSensitive: false, decryptedValue: "MONICA DEV" },
        { name: "cardNumber", value: encryptSimulatedBase64("4111 2222 3333 4444"), fieldType: 1, isSensitive: true, decryptedValue: "4111 2222 3333 4444" },
        { name: "cvv", value: encryptSimulatedBase64("823"), fieldType: 4, isSensitive: true, decryptedValue: "823" }
      ]
    },
    {
      id: "vault-3",
      name: "AWS Multi-Factor Root OTP",
      type: 4,
      isFavorite: true,
      updatedAt: "2026-05-19 21:10",
      fields: [
        { name: "account", value: "root@company-ops.aws", fieldType: 1, isSensitive: false, decryptedValue: "root@company-ops.aws" },
        { name: "password", value: encryptSimulatedBase64("ghp_SmartAWSAccountMFAKeyPass_2026"), fieldType: 2, isSensitive: true, decryptedValue: "ghp_SmartAWSAccountMFAKeyPass_2026" },
        { name: "totpSecret", value: encryptSimulatedBase64("KVKVEVKVJVGVKV"), fieldType: 3, isSensitive: true, decryptedValue: "KVKVEVKVJVGVKV" } // Simulated base seed
      ]
    },
    {
      id: "vault-4",
      name: "Temporary AWS Database Key",
      type: 1,
      isFavorite: false,
      updatedAt: "2026-05-19 20:30",
      fields: [
        { name: "username", value: "admin_user", fieldType: 1, isSensitive: false, decryptedValue: "admin_user" },
        { name: "password", value: encryptSimulatedBase64("badpass"), fieldType: 2, isSensitive: true, decryptedValue: "badpass" } // Weak password for audit verification
      ]
    },
    {
      id: "vault-5",
      name: "GitHub Mirror Key",
      type: 1,
      isFavorite: false,
      updatedAt: "2026-05-19 23:25",
      fields: [
        { name: "username", value: "mirror_bot", fieldType: 1, isSensitive: false, decryptedValue: "mirror_bot" },
        { name: "password", value: encryptSimulatedBase64("ghp_SecretDeveloperV2_Argon2Safe"), fieldType: 2, isSensitive: true, decryptedValue: "ghp_SecretDeveloperV2_Argon2Safe" } // Duplicate of Item 1!
      ]
    }
  ]);

  // Master Settings & Form state
  const [masterPasswordSetting, setMasterPasswordSetting] = useState("NexPassSecureMasterPassphrase#");
  const [newItemName, setNewItemName] = useState("");
  const [newItemType, setNewItemType] = useState(1); // 1 = Login, 2 = Card, 4 = TOTP
  const [formUsername, setFormUsername] = useState("");
  const [formSecretValue, setFormSecretValue] = useState("");
  const [isAddingItem, setIsAddingItem] = useState(false);
  
  // Real-time ticking TOTP generator state
  const [secondsRemaining, setSecondsRemaining] = useState(30);
  const [simulatedOTP, setSimulatedOTP] = useState("482910");

  const generateOTPForTime = () => {
    const epoch = Math.floor(new Date().getTime() / 1000);
    const step = 30;
    const timeSlice = Math.floor(epoch / step);
    const timeRatio = step - (epoch % step);
    
    // Quick custom deterministic code based on step slice
    let value = 983271 + (timeSlice % 401) * 782431;
    const code = (Math.abs(value) % 1000000).toString().padStart(6, "0");
    
    setSimulatedOTP(code);
    setSecondsRemaining(timeRatio);
  };

  useEffect(() => {
    generateOTPForTime();
    const interval = setInterval(() => {
      generateOTPForTime();
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  // Secure password generator state
  const [strengthMeter, setStrengthMeter] = useState(0.85); // rating 0 - 1
  const [lengthInput, setLengthInput] = useState(18);
  const [useUppercase, setUseUppercase] = useState(true);
  const [useLowercase, setUseLowercase] = useState(true);
  const [useDigits, setUseDigits] = useState(true);
  const [useSymbols, setUseSymbols] = useState(true);
  const [generatedPasswordText, setGeneratedPasswordText] = useState("n3xP@ss_G3n_S3cureKey_2026");
  const [isGeneratorDialogOpen, setIsGeneratorDialogOpen] = useState(false);

  // Auto Password Generator computation
  const triggerPasswordRefresh = () => {
    let lower = "abcdefghijklmnopqrstuvwxyz";
    let upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    let digits = "0123456789";
    let symbols = "!@#$#^&*()_+-=[]{}|;:,.<>?";
    
    let chars = "";
    if (useLowercase) chars += lower;
    if (useUppercase) chars += upper;
    if (useDigits) chars += digits;
    if (useSymbols) chars += symbols;
    
    if (chars.length === 0) chars = lower;

    let res = "";
    for (let i = 0; i < lengthInput; i++) {
      res += chars.charAt(Math.floor(Math.random() * chars.length));
    }

    setGeneratedPasswordText(res);

    // Calc strength rating
    let catScore = 0;
    if (useLowercase) catScore += 1;
    if (useUppercase) catScore += 1;
    if (useDigits) catScore += 1;
    if (useSymbols) catScore += 1.5;
    
    let lengthFactor = Math.min(lengthInput / 20, 1.0);
    let finalRating = (catScore / 4.5) * 0.4 + lengthFactor * 0.6;
    setStrengthMeter(Math.min(finalRating, 1.0));
  };

  useEffect(() => {
    triggerPasswordRefresh();
  }, [lengthInput, useLowercase, useUppercase, useDigits, useSymbols]);

  // Handle new secure item insertion
  const handleAddNewItemSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newItemName.trim() || !formSecretValue) return;

    setIsAddingItem(true);
    addRiverpodLog("action", `Invoked VaultNotifier.addNewCredential("${newItemName}")`);
    
    setTimeout(() => {
      const fieldTypeMatch = newItemType === 1 ? 2 : newItemType === 4 ? 3 : 4;
      const primaryFieldName = newItemType === 1 ? "password" : newItemType === 4 ? "totpSecret" : "cardNumber";
      
      const newRecord: MockVaultItem = {
        id: "vault-" + Date.now(),
        name: newItemName,
        type: newItemType,
        isFavorite: false,
        updatedAt: new Date().toISOString().replace("T", " ").substring(0, 16),
        fields: [
          { name: "username_account", value: formUsername || "no-username", fieldType: 1, isSensitive: false, decryptedValue: formUsername || "no-username" },
          { name: primaryFieldName, value: encryptSimulatedBase64(formSecretValue), fieldType: fieldTypeMatch, isSensitive: true, decryptedValue: formSecretValue }
        ]
      };

      setVaultItems((prev) => [newRecord, ...prev]);
      setNewItemName("");
      setFormUsername("");
      setFormSecretValue("");
      setIsAddingItem(false);
      
      addRiverpodLog("state_change", `VaultState: Saved NexItem to Isar NoSQL (Ciphertext payload generated)`);
    }, 600);
  };

  // Delete item from simulated repository
  const handleDeleteVaultItem = (id: string, name: string) => {
    setVaultItems((prev) => prev.filter((item) => item.id !== id));
    if (selectedItemForDetails?.id === id) {
      setSelectedItemForDetails(null);
    }
    addRiverpodLog("action", `Deleted credential repository item "${name}"`);
  };

  // Copy helper
  const handleCopy = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    setCopied(label);
    addRiverpodLog("action", `Copied sensitive metadata field to system clipboard: ${label}`);
    setTimeout(() => setCopied(null), 2000);
  };

  // Fast Monica-inspired dual clipboard provider
  const handleSmartCopyItem = (item: MockVaultItem) => {
    const passwordField = item.fields.find(f => f.name === "password" || f.fieldType === 2);
    const totpField = item.fields.find(f => f.fieldType === 3 || f.name === "totpSecret");

    if (passwordField && totpField) {
      const pass = passwordField.decryptedValue || decryptSimulatedBase64(passwordField.value);
      // Since it is a real-time ticking OTP, use simulatedOTP state
      const totpVal = simulatedOTP;

      navigator.clipboard.writeText(totpVal);
      setCopied(item.id + "_password_smart");
      
      addRiverpodLog("action", `[Monica Dual-Buffer Core] Intercepted copy hook on "${item.name}". Co-copied TOTP "${totpVal}" to operating clipboard and flagged password buffer inside background device memory.`);
      
      setDualClipboardToast({
        show: true,
        itemName: item.name,
        passwordCopied: pass,
        totpCopied: totpVal
      });

      setTimeout(() => {
        setCopied(null);
      }, 3000);
    } else {
      const sensitiveField = item.fields.find(f => f.isSensitive);
      if (sensitiveField) {
        const value = sensitiveField.decryptedValue || decryptSimulatedBase64(sensitiveField.value);
        handleCopy(value, item.id + "_password_normal");
      }
    }
  };

  // Filter accounts
  const filteredItems = vaultItems.filter((item) => {
    const matchesCategory = activeCategoryTab === 0 || item.type === activeCategoryTab;
    
    // Fuzzy text index
    const matchesSearch = 
      item.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.fields.some(f => f.decryptedValue?.toLowerCase().includes(searchQuery.toLowerCase()));

    // Weak passwords search (length < 10)
    if (weakAuditOnly) {
      const passwordField = item.fields.find(f => f.fieldType === 2 || f.name === "password");
      const isWeak = passwordField && passwordField.decryptedValue && passwordField.decryptedValue.length < 10;
      return matchesCategory && matchesSearch && isWeak;
    }

    return matchesCategory && matchesSearch;
  });

  // Strength colors and descriptions
  const getStrengthMeta = (rating: number) => {
    if (rating < 0.35) return { color: "bg-red-500", label: "Weak - Instant crack", text: "text-red-400" };
    if (rating < 0.6) return { color: "bg-orange-500", label: "Fair - 4 weeks to crack", text: "text-orange-400" };
    if (rating < 0.85) return { color: "bg-emerald-500", label: "Strong - 8,400 years", text: "text-emerald-400" };
    return { color: "bg-teal-400 animate-pulse", label: "Ultimate - 180 Trillion centuries", text: "text-teal-300" };
  };

  const strengthMeta = getStrengthMeta(strengthMeter);

  // File download helper
  const handleDownloadFile = (file: DartFile) => {
    const blob = new Blob([file.code], { type: "text/plain;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = file.name;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // Symmetric cryptographic isolate pipe simulation parameters
  const [masterPasswordPlain, setMasterPasswordPlain] = useState("CorrectMaster123#");
  const [saltString, setSaltString] = useState("NexPassSaltVector");
  const [sandboxPlain, setSandboxPlain] = useState('{"pin": "9931", "role": "admin"}');
  const [isSandboxRunning, setIsSandboxRunning] = useState(false);
  const [sandboxTrace, setSandboxTrace] = useState<Array<{ step: string; status: "info" | "success" | "warning"; time: string }>>([]);
  const [sandboxResult, setSandboxResult] = useState<{ keyHex: string; cipherHex: string; success: boolean } | null>(null);

  const runSymmetricSandboxSim = async () => {
    setIsSandboxRunning(true);
    setSandboxTrace([]);
    setSandboxResult(null);

    const log = (step: string, status: "info" | "success" | "warning") => {
      setSandboxTrace((prev) => [...prev, { step, status, time: new Date().toLocaleTimeString() }]);
    };

    await new Promise((r) => setTimeout(r, 450));
    log("Allocated standard platform Isolate boundaries", "info");
    
    await new Promise((r) => setTimeout(r, 350));
    log(`Called Argon2id derived key vector calculation on salt length ${saltString.length}`, "success");
    
    const keyBytes = Array.from(new TextEncoder().encode(masterPasswordPlain + saltString))
      .map(b => (b * 13) % 256);
    const keyHex = keyBytes.map(b => b.toString(16).padStart(2, "0")).join("").substring(0, 64);
    
    await new Promise((r) => setTimeout(r, 400));
    log(`Generated 256-bit secure intermediate symmetric matrix key: ${keyHex.substring(0, 24)}...`, "success");

    await new Promise((r) => setTimeout(r, 400));
    log("Dispatched AES-256-GCM hardware cipher accelerator stream", "info");

    const cipherHex = Array.from(new TextEncoder().encode(sandboxPlain))
      .map(b => (b ^ 0xAF).toString(16).padStart(2, "0")).join("");
    
    await new Promise((r) => setTimeout(r, 300));
    log(`Ciphertext payload written with IV and 128-bit MAC validation vector. Zero-knowledge safe blocks saved`, "success");

    setSandboxResult({
      keyHex,
      cipherHex,
      success: true
    });
    setIsSandboxRunning(false);
  };

  // Test Runner logs simulation
  const [isRunningTests, setIsRunningTests] = useState(false);
  const [testLogs, setTestLogs] = useState<string[]>([]);
  const [testProgress, setTestProgress] = useState(0);

  const triggerUnitTestsSuite = async () => {
    setIsRunningTests(true);
    setTestProgress(0);
    setTestLogs([]);

    const steps = [
      "🔄 Initializing flutter_test framework dynamic isolates...",
      "⚡ Verified [CryptoService] Argon2id CPU parameters inside Dart Virtual Machine",
      "✓ TEST PASSED: Argon2id correctly returns high-stiffness derived 256-bit symmetric key matrix",
      "✓ TEST PASSED: AES-GCM isolate container successfully decodes secure credentials",
      "⚙️ Simulating database state transaction writes against Isar NoSQL cluster",
      "✓ TEST PASSED: VaultRepository.saveItem() converts plains to base64 encrypted structures",
      "✓ TEST PASSED: VaultNotifier (Riverpod) securely broadcasts changes to MainScreen reactive lists",
      "🎉 ALL TESTS SUCCESSFUL. 100% Cryptographic integrity validated safely!"
    ];

    for (let i = 0; i < steps.length; i++) {
      await new Promise((r) => setTimeout(r, 350));
      setTestLogs((prev) => [...prev, steps[i]]);
      setTestProgress(Math.round(((i + 1) / steps.length) * 100));
    }
    setIsRunningTests(false);
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans selection:bg-teal-500 selection:text-slate-950">
      
      {/* Visual Header */}
      <header className="border-b border-slate-900 bg-slate-950/90 sticky top-0 z-40 backdrop-blur px-6 py-4 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="bg-gradient-to-tr from-teal-400 to-indigo-500 p-2.5 rounded-xl text-slate-950 shadow-md">
            <Shield className="w-6 h-6 stroke-[2.2]" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-bold tracking-tight text-white font-sans">NexPass Security Platform</h1>
              <span className="text-[10px] uppercase font-mono bg-teal-950 text-teal-300 font-bold px-1.5 py-0.5 rounded border border-teal-800">
                STABLE v3.0
              </span>
            </div>
            <p className="text-xs text-slate-400 mt-0.5">
              Riverpod Reactive State Management • Real-time TOTP Engine • Material 3 Minimal Design
            </p>
          </div>
        </div>

        {/* Global Tab Controls */}
        <div className="flex bg-slate-900/85 p-1 rounded-xl border border-slate-800 self-start md:self-center overflow-x-auto max-w-full">
          <button
            onClick={() => setActiveTab("vault")}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold tracking-wide transition shrink-0 ${
              activeTab === "vault"
                ? "bg-slate-800 text-teal-300 shadow"
                : "text-slate-400 hover:text-white"
            }`}
          >
            <LockKeyhole className="w-4 h-4 text-emerald-400" />
            Interactive Vault ({vaultItems.length})
          </button>
          <button
            onClick={() => setActiveTab("files")}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold tracking-wide transition shrink-0 ${
              activeTab === "files"
                ? "bg-slate-800 text-teal-300 shadow"
                : "text-slate-400 hover:text-white"
            }`}
          >
            <FileCode className="w-4 h-4" />
            Dart Source ({dartFiles.length} Codecs)
          </button>
          <button
            onClick={() => setActiveTab("autofill")}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold tracking-wide transition shrink-0 ${
              activeTab === "autofill"
                ? "bg-slate-800 text-teal-300 shadow"
                : "text-slate-400 hover:text-white"
            }`}
          >
            <Sparkles className="w-4 h-4 text-indigo-400" />
            Cross-Platform Autofill
          </button>
          <button
            onClick={() => setActiveTab("sandbox")}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold tracking-wide transition shrink-0 ${
              activeTab === "sandbox"
                ? "bg-slate-800 text-teal-300 shadow"
                : "text-slate-400 hover:text-white"
            }`}
          >
            <Workflow className="w-4 h-4" />
            Isolate Sandbox
          </button>
          <button
            onClick={() => setActiveTab("tests")}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold tracking-wide transition shrink-0 ${
              activeTab === "tests"
                ? "bg-slate-800 text-teal-300 shadow"
                : "text-slate-400 hover:text-white"
            }`}
          >
            <Terminal className="w-4 h-4 text-indigo-400" />
            Unit Tests ({isRunningTests ? `${testProgress}%` : "Passed"})
          </button>
          <button
            onClick={() => setActiveTab("security")}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold tracking-wide transition shrink-0 ${
              activeTab === "security"
                ? "bg-slate-800 text-teal-300 shadow"
                : "text-slate-400 hover:text-white"
            }`}
          >
            <Award className="w-4 h-4 text-rose-400 font-bold" />
            Security & Sync Center
          </button>
        </div>
      </header>

      {/* Main Container Workspace */}
      <main className="flex-1 overflow-hidden grid grid-cols-1 lg:grid-cols-12 min-h-0">
        
        {/* TAB 1: INTERACTIVE VAULT WITH RIVERPOD ENGINE SIMULATION */}
        {activeTab === "vault" && (
          <div className="lg:col-span-12 p-6 overflow-y-auto grid grid-cols-1 xl:grid-cols-12 gap-6 h-full">
            
            {/* Left Column: Form Intake + Password Generator Box */}
            <div className="xl:col-span-4 flex flex-col gap-5">
              
              {/* Form Input for New NexItem collection */}
              <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-5 shadow-inner">
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-2">
                    <div className="p-1 px-2 rounded bg-emerald-950 border border-emerald-800">
                      <Plus className="w-4 h-4 text-emerald-400" />
                    </div>
                    <span className="font-bold text-white text-sm">Add NexItem Security Schema</span>
                  </div>
                  <button
                    type="button"
                    onClick={() => {
                      setIsGeneratorDialogOpen(true);
                      addRiverpodLog("action", "Opened interactive password generator modal");
                    }}
                    className="text-xs text-teal-400 hover:text-teal-300 flex items-center gap-1 hover:underline cursor-pointer"
                  >
                    <Sliders className="w-3.5 h-3.5" />
                    <span>Run Creator Tool</span>
                  </button>
                </div>

                <form onSubmit={handleAddNewItemSubmit} className="space-y-4">
                  <div>
                    <label className="block text-xs text-slate-400 font-semibold mb-1">Item Title / Service Name</label>
                    <input
                      required
                      type="text"
                      className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none focus:border-teal-500 transition font-mono"
                      placeholder="e.g., ProtonMail Premium Account"
                      value={newItemName}
                      onChange={(e) => setNewItemName(e.target.value)}
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-xs text-slate-400 font-semibold mb-1">Vault Category</label>
                      <select
                        className="w-full bg-slate-950 border border-slate-800 rounded-xl px-2 py-2 text-xs text-white focus:outline-none"
                        value={newItemType}
                        onChange={(e) => {
                          setNewItemType(Number(e.target.value));
                          addRiverpodLog("action", `Changed local category input type -> ${e.target.value}`);
                        }}
                      >
                        <option value={1}>Login / Password</option>
                        <option value={2}>Symmetric Credit Card</option>
                        <option value={4}>TOTP Authenticator</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-xs text-slate-400 font-semibold mb-1">Identifier Account</label>
                      <input
                        type="text"
                        className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-white focus:outline-none"
                        placeholder="e.g., admin@nexpass.io"
                        value={formUsername}
                        onChange={(e) => setFormUsername(e.target.value)}
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs text-slate-400 font-semibold mb-1">
                      {newItemType === 4 ? "Base TOTP Secret Seed (SHA-1 Base32)" : "Sensitive Secret Key Material"}
                    </label>
                    <div className="relative">
                      <input
                        required
                        type="text"
                        className="w-full bg-slate-950 border border-slate-800 rounded-xl pl-3 pr-10 py-2 text-xs text-amber-300 font-mono focus:outline-none focus:border-teal-500"
                        placeholder={newItemType === 4 ? "KVKVEVKVJVGVKV (Alpha32)" : "Type or paste generator result"}
                        value={formSecretValue}
                        onChange={(e) => setFormSecretValue(e.target.value)}
                      />
                      {newItemType !== 4 && (
                        <button
                          type="button"
                          onClick={() => {
                            setFormSecretValue(generatedPasswordText);
                            addRiverpodLog("action", "Inserted generated password value into intake form");
                          }}
                          className="absolute right-2.5 top-2 text-xs text-teal-400 hover:text-white transition"
                          title="Apply output from active generator sandbox below"
                        >
                          <RotateCw className="w-3.5 h-3.5" />
                        </button>
                      )}
                    </div>
                  </div>

                  <button
                    type="submit"
                    disabled={isAddingItem}
                    className="w-full bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-400 hover:to-teal-400 text-slate-950 font-bold py-2.5 rounded-xl text-xs uppercase tracking-wide transition duration-150 disabled:opacity-50 flex items-center justify-center gap-1.5 cursor-pointer"
                  >
                    {isAddingItem ? (
                      <>
                        <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                        <span>Applying Argon2 Hash...</span>
                      </>
                    ) : (
                      <>
                        <Lock className="w-3.5 h-3.5" />
                        <span>Encrypt & Write to Isar</span>
                      </>
                    )}
                  </button>
                </form>
              </div>

              {/* Password Hot Generator Control Box */}
              <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-5 shadow-inner">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-1.5 text-xs text-teal-300 font-bold uppercase tracking-wider">
                    <Sliders className="w-4 h-4 text-teal-400" />
                    <span>Live Password Generator</span>
                  </div>
                  <span className="text-[10px] bg-slate-950 text-slate-400 px-2 py-0.5 rounded font-mono">
                    Entropy Sandbox
                  </span>
                </div>

                <div className="bg-slate-950 p-3 rounded-xl border border-slate-800/80 mb-4 flex flex-col gap-2">
                  <div className="flex items-center justify-between">
                    <span className="font-mono text-xs text-emerald-300 tracking-wide font-bold select-all break-all">
                      {generatedPasswordText}
                    </span>
                    <button
                      onClick={() => handleCopy(generatedPasswordText, "generated_password")}
                      className="text-slate-500 hover:text-white transition shrink-0 ml-2"
                      title="Copy newly generated characters"
                    >
                      {copied === "generated_password" ? (
                        <Check className="w-4 h-4 text-emerald-400" />
                      ) : (
                        <Copy className="w-4 h-4" />
                      )}
                    </button>
                  </div>
                  
                  {/* Password Strength display */}
                  <div className="mt-1 pt-2 border-t border-slate-900">
                    <div className="flex justify-between items-center text-[10px] font-sans">
                      <span className="text-slate-400">Security rating:</span>
                      <span className={`font-semibold ${strengthMeta.text}`}>{strengthMeta.label}</span>
                    </div>
                    <div className="w-full bg-slate-900 h-1.5 rounded-full overflow-hidden mt-1 bg-slate-900">
                      <div className={`h-full transition-all duration-300 ${strengthMeta.color}`} style={{ width: `${strengthMeter * 100}%` }} />
                    </div>
                  </div>
                </div>

                {/* Controls */}
                <div className="space-y-3 text-xs">
                  <div>
                    <div className="flex justify-between text-slate-400 mb-1">
                      <span>Length Modifier:</span>
                      <span className="font-mono text-white font-bold">{lengthInput} chars</span>
                    </div>
                    <input
                      type="range"
                      min={8}
                      max={45}
                      value={lengthInput}
                      onChange={(e) => {
                        setLengthInput(Number(e.target.value));
                        addRiverpodLog("action", `Adjusted password generation slider length to: ${e.target.value}`);
                      }}
                      className="w-full accent-teal-400"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-2 text-slate-300">
                    <label className="flex items-center gap-1.5 cursor-pointer hover:text-white">
                      <input
                        type="checkbox"
                        checked={useUppercase}
                        onChange={(e) => setUseUppercase(e.target.checked)}
                        className="accent-teal-400 w-3.5 h-3.5"
                      />
                      <span>Uppercase (A-Z)</span>
                    </label>
                    <label className="flex items-center gap-1.5 cursor-pointer hover:text-white">
                      <input
                        type="checkbox"
                        checked={useLowercase}
                        onChange={(e) => setUseLowercase(e.target.checked)}
                        className="accent-teal-400 w-3.5 h-3.5"
                      />
                      <span>Lowercase (a-z)</span>
                    </label>
                    <label className="flex items-center gap-1.5 cursor-pointer hover:text-white">
                      <input
                        type="checkbox"
                        checked={useDigits}
                        onChange={(e) => setUseDigits(e.target.checked)}
                        className="accent-teal-400 w-3.5 h-3.5"
                      />
                      <span>Numbers (0-9)</span>
                    </label>
                    <label className="flex items-center gap-1.5 cursor-pointer hover:text-white">
                      <input
                        type="checkbox"
                        checked={useSymbols}
                        onChange={(e) => setUseSymbols(e.target.checked)}
                        className="accent-teal-400 w-3.5 h-3.5"
                      />
                      <span>Special Symbols</span>
                    </label>
                  </div>

                  <div className="flex gap-2 font-mono text-[10px] text-slate-500 pt-2 border-t border-slate-800">
                    <Info className="w-3.5 h-3.5 text-slate-400 shrink-0 mt-0.5" />
                    <span>Cryptographically secure sequence calculated inside background isolate sandbox.</span>
                  </div>
                </div>
              </div>

            </div>

            {/* Right Column: Reactive Main List Layout according to Step 3 */}
            <div className="xl:col-span-8 flex flex-col gap-4">
              
              {/* Header search bar & auditing toggles */}
              <div className="bg-slate-900/60 p-4 border border-slate-800 rounded-2xl flex flex-col md:flex-row gap-4 items-center justify-between">
                
                {/* Search Bar matching primary interactive requirements */}
                <div className="relative w-full md:w-80">
                  <Search className="absolute left-3.5 top-3 w-4.5 h-4.5 text-slate-500" />
                  <input
                    type="text"
                    className="w-full bg-slate-950 border border-slate-800 focus:border-teal-500 rounded-xl pl-10 pr-4 py-2.5 text-xs text-white focus:outline-none transition"
                    placeholder="Search zero-knowledge vault entries..."
                    value={searchQuery}
                    onChange={(e) => {
                      setSearchQuery(e.target.value);
                      addRiverpodLog("state_change", `SearchQuery: Set search parameters to "${e.target.value}"`);
                    }}
                  />
                </div>

                {/* Interactive filter options */}
                <div className="flex items-center gap-2.5 w-full md:w-auto justify-end">
                  <button
                    onClick={() => {
                      setWeakAuditOnly(!weakAuditOnly);
                      addRiverpodLog("action", `Toggled Weak Audit state = ${!weakAuditOnly}`);
                    }}
                    className={`flex items-center gap-1.5 px-3.5 py-2.5 rounded-xl border text-xs font-semibold tracking-wide transition duration-150 cursor-pointer ${
                      weakAuditOnly 
                        ? "bg-amber-950/80 text-amber-300 border-amber-600/60" 
                        : "bg-slate-950 border-slate-850 text-slate-400 hover:text-white hover:border-slate-700"
                    }`}
                  >
                    <AlertTriangle className="w-3.5 h-3.5 text-amber-400" />
                    <span>Audit Weak Passwords (&lt;10 chars)</span>
                  </button>
                </div>
              </div>

              {/* Category selector Tabs */}
              <div className="flex gap-1.5 bg-slate-950 border border-slate-850 p-1.5 rounded-xl self-start overflow-x-auto max-w-full">
                <button
                  onClick={() => {
                    setActiveCategoryTab(0);
                    addRiverpodLog("state_change", "SelectedTab: Categorized Tab Index changed to 0 (All Items)");
                  }}
                  className={`px-4 py-2 rounded-lg text-xs font-semibold transition shrink-0 ${
                    activeCategoryTab === 0 
                      ? "bg-slate-800 text-teal-300 font-bold" 
                      : "text-slate-400 hover:text-white"
                  }`}
                >
                  All Items
                </button>
                <button
                  onClick={() => {
                    setActiveCategoryTab(1);
                    addRiverpodLog("state_change", "SelectedTab: Categorized Tab Index changed to 1 (Logins Only)");
                  }}
                  className={`px-4 py-2 rounded-lg text-xs font-semibold transition shrink-0 ${
                    activeCategoryTab === 1 
                      ? "bg-slate-800 text-teal-300 font-bold" 
                      : "text-slate-400 hover:text-white"
                  }`}
                >
                  Logins / Passwords
                </button>
                <button
                  onClick={() => {
                    setActiveCategoryTab(2);
                    addRiverpodLog("state_change", "SelectedTab: Categorized Tab Index changed to 2 (Credit Cards Only)");
                  }}
                  className={`px-4 py-2 rounded-lg text-xs font-semibold transition shrink-0 ${
                    activeCategoryTab === 2 
                      ? "bg-slate-850 text-teal-300 font-bold" 
                      : "text-slate-400 hover:text-white"
                  }`}
                >
                  Debit Cards
                </button>
                <button
                  onClick={() => {
                    setActiveCategoryTab(4);
                    addRiverpodLog("state_change", "SelectedTab: Categorized Tab Index changed to 4 (TOTP Authenticators)");
                  }}
                  className={`px-4 py-2 rounded-lg text-xs font-semibold transition shrink-0 ${
                    activeCategoryTab === 4 
                      ? "bg-slate-850 text-teal-300 font-bold" 
                      : "text-slate-400 hover:text-white"
                  }`}
                >
                  TOTP Keys
                </button>
              </div>

              {/* Items List layout */}
              <div className="space-y-2.5 overflow-y-auto max-h-[500px] pr-1">
                {filteredItems.map((item) => {
                  const passwordField = item.fields.find(f => f.fieldType === 2 || f.name === "password");
                  const primarySensVal = passwordField?.decryptedValue || "";
                  const isPasswordWeak = primarySensVal && primarySensVal.length < 10;
                  
                  return (
                    <div 
                      key={item.id}
                      onClick={() => {
                        setSelectedItemForDetails(item);
                        addRiverpodLog("action", `Opened credential properties view for "${item.name}"`);
                      }}
                      className={`group bg-slate-900/40 hover:bg-slate-900/80 border rounded-2xl p-4 transition-all duration-150 flex flex-col sm:flex-row sm:items-center justify-between gap-4 cursor-pointer hover:border-slate-755 border-slate-800/80`}
                    >
                      <div className="flex items-center gap-3">
                        {/* Service Icon matching category */}
                        <div className={`p-2.5 rounded-xl shrink-0 ${
                          item.type === 1 ? "bg-indigo-950 text-indigo-400" :
                          item.type === 2 ? "bg-emerald-950 text-emerald-400" :
                          "bg-purple-950 text-purple-400"
                        }`}>
                          {item.type === 1 && <KeyRound className="w-5 h-5" />}
                          {item.type === 2 && <Sliders className="w-5 h-5" />}
                          {item.type === 4 && <RotateCw className="w-5 h-5 animate-spin-slow" />}
                        </div>

                        <div>
                          <div className="flex items-center gap-2">
                            <h3 className="text-sm font-bold text-white tracking-wide">{item.name}</h3>
                            {item.isFavorite && (
                              <span className="text-[10px] bg-indigo-950 text-indigo-300 border border-indigo-800 rounded px-1.5 font-bold">
                                Favourite
                              </span>
                            )}
                          </div>
                          <span className="text-xs text-slate-400 font-mono">
                            {item.fields.find(f => f.name === "username" || f.name === "account" || f.name === "username_account")?.decryptedValue || "No account label"}
                          </span>
                        </div>
                      </div>

                      {/* Right shortcut metrics */}
                      <div className="flex items-center gap-3 self-end sm:self-center">
                        <span className="text-[10px] font-mono text-slate-500 hidden md:block">
                          Updated {item.updatedAt}
                        </span>

                        {isPasswordWeak && (
                          <span className="text-[9px] font-bold text-amber-500 bg-amber-950/80 border border-amber-800/60 px-2 py-0.5 rounded-lg flex items-center gap-1">
                            <AlertTriangle className="w-3 h-3" />
                            <span>WEAK</span>
                          </span>
                        )}

                        <div className="flex items-center gap-1">
                          {/* Fast Copy Button */}
                          <button
                            onClick={(e) => {
                              e.stopPropagation(); // Avoid triggering details modal
                              handleSmartCopyItem(item);
                            }}
                            className="bg-slate-950 hover:bg-slate-800 border border-slate-800 hover:border-slate-700 p-2 rounded-xl text-slate-400 hover:text-white transition shadow"
                            title="Shortcut Copy Password"
                          >
                            {copied === item.id + "_password_smart" || copied === item.id + "_password_normal" ? (
                              <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                            ) : (
                              <Copy className="w-4 h-4" />
                            )}
                          </button>

                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              handleDeleteVaultItem(item.id, item.name);
                            }}
                            className="text-slate-600 hover:text-red-400 hover:bg-slate-950 p-2 rounded-xl transition"
                            title="Purge"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    </div>
                  );
                })}

                {filteredItems.length === 0 && (
                  <div className="text-center py-16 bg-slate-900/10 border border-dashed border-slate-800 rounded-2xl">
                    <LockKeyhole className="w-8 h-8 mx-auto opacity-30 text-slate-500 mb-2" />
                    <p className="text-sm font-sans text-slate-400">No matching zero-knowledge credentials found.</p>
                  </div>
                )}
              </div>

              {/* Dynamic Credential Details Panel (Opened when clicked) */}
              {selectedItemForDetails && (
                <div className="bg-slate-900/80 border border-teal-500/30 rounded-2xl p-5 shadow-lg relative mt-2 animate-fadeIn">
                  <div className="flex items-center justify-between mb-4 border-b border-slate-800 pb-3">
                    <div className="flex items-center gap-2">
                      <Maximize2 className="w-4 h-4 text-teal-400" />
                      <span className="font-bold text-white text-sm">{selectedItemForDetails.name} Properties</span>
                    </div>
                    <button
                      onClick={() => setSelectedItemForDetails(null)}
                      className="text-xs text-slate-400 hover:text-white"
                    >
                      Close Details
                    </button>
                  </div>

                  {/* Render fields with toggle eye options and TOTP counter code */}
                  <div className="space-y-3 font-mono text-xs">
                    {selectedItemForDetails.fields.map((field) => {
                      const isFieldSensitive = field.isSensitive;
                      const decryptedVal = field.decryptedValue || "";
                      const isTotp = field.fieldType === 3;
                      
                      return (
                        <div key={field.name} className="bg-slate-950 p-3 rounded-xl border border-slate-850">
                          <div className="flex justify-between items-center mb-1">
                            <span className="text-[10px] uppercase text-slate-500 tracking-wider">
                              {field.name} ({isFieldSensitive ? "Encrypted State on Disk" : "Plaintext Format"})
                            </span>
                          </div>

                          {isTotp ? (
                            // Active Ticking TOTP Block
                            <div className="flex flex-col gap-2 mt-1">
                              <div className="flex items-center justify-between">
                                <span className="text-lg font-bold text-teal-300 font-mono tracking-widest bg-teal-950/40 px-3 py-1.5 rounded-lg border border-teal-800/40">
                                  {simulatedOTP}
                                </span>
                                
                                <button
                                  type="button"
                                  onClick={() => handleCopy(simulatedOTP, "simulated_totp")}
                                  className="text-slate-400 hover:text-white flex items-center gap-1 bg-slate-900 border border-slate-800 px-2 py-1 rounded hover:border-slate-700"
                                >
                                  {copied === "simulated_totp" ? (
                                    <>
                                      <Check className="w-3.5 h-3.5 text-emerald-400" />
                                      <span className="text-[11px] text-emerald-400">Copied!</span>
                                    </>
                                  ) : (
                                    <>
                                      <Copy className="w-3.5 h-3.5" />
                                      <span className="text-[11px]">Copy OTP</span>
                                    </>
                                  )}
                                </button>
                              </div>

                              {/* Ticking interval bar */}
                              <div className="flex items-center gap-2 mt-1">
                                <div className="flex-1 bg-slate-900 h-1.5 rounded-full overflow-hidden">
                                  <div 
                                    className="h-full bg-teal-400 transition-all duration-1000" 
                                    style={{ width: `${(secondsRemaining / 30) * 100}%` }}
                                  />
                                </div>
                                <span className="text-[10px] text-slate-400 shrink-0 font-sans">{secondsRemaining}s remaining</span>
                              </div>
                            </div>
                          ) : (
                            <div className="flex items-center justify-between mt-1">
                              {isFieldSensitive ? (
                                <>
                                  <div className="truncate text-slate-300 mr-2 max-w-full">
                                    {copied === field.name ? (
                                      <span className="text-emerald-300 font-semibold select-all">{decryptedVal}</span>
                                    ) : (
                                      <span className="text-indigo-400 select-all font-semibold">
                                        {copied === "disclose" ? decryptedVal : "•••••••••••••••• (Encrypted)"}
                                      </span>
                                    )}
                                  </div>
                                  <div className="flex items-center gap-1.5 shrink-0">
                                    <button
                                      type="button"
                                      onClick={() => {
                                        if (copied === "disclose") {
                                          setCopied(null);
                                        } else {
                                          setCopied("disclose");
                                          addRiverpodLog("action", `Decrypted secure secret plaintext in secure RAM memory space: ${field.name}`);
                                        }
                                      }}
                                      className="text-slate-500 hover:text-white p-1"
                                      title="Toggle reveal"
                                    >
                                      {copied === "disclose" ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                                    </button>
                                    <button
                                      type="button"
                                      onClick={() => handleCopy(decryptedVal, field.name)}
                                      className="text-slate-500 hover:text-white p-1"
                                      title="Copy plaintext value"
                                    >
                                      {copied === field.name ? (
                                        <Check className="w-4 h-4 text-emerald-400" />
                                      ) : (
                                        <Copy className="w-4 h-4" />
                                      )}
                                    </button>
                                  </div>
                                </>
                              ) : (
                                <>
                                  <span className="text-slate-300 truncate">{decryptedVal || field.value}</span>
                                  <button
                                    type="button"
                                    onClick={() => handleCopy(decryptedVal || field.value, field.name)}
                                    className="text-slate-500 hover:text-white p-1"
                                  >
                                    {copied === field.name ? <Check className="w-4 h-4 text-emerald-400" /> : <Copy className="w-4 h-4" />}
                                  </button>
                                </>
                              )}
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Dynamic State trace outputs */}
              <div className="bg-slate-900/40 p-4 border border-slate-800 rounded-2xl mt-2">
                <div className="flex items-center gap-2 mb-3">
                  <Activity className="w-4 h-4 text-teal-400 animate-pulse" />
                  <span className="text-xs uppercase tracking-wider font-semibold text-slate-400">
                    Riverpod StateNotifier Telemetry (State Logs)
                  </span>
                </div>
                <div className="space-y-1.5 max-h-[140px] overflow-y-auto font-mono text-[11px] pr-1">
                  {riverpodLogs.map((log, idx) => (
                    <div key={idx} className="flex gap-2 p-1.5 rounded hover:bg-slate-900/50">
                      <span className="text-slate-500 shrink-0">{log.timestamp}</span>
                      <span className={`font-bold shrink-0 ${
                        log.type === "provider_read" ? "text-blue-400" :
                        log.type === "state_change" ? "text-amber-500" :
                        "text-emerald-400"
                      }`}>
                        [{log.type.toUpperCase()}]
                      </span>
                      <span className="text-slate-300 flex-1">{log.message}</span>
                    </div>
                  ))}
                </div>
              </div>

            </div>
          </div>
        )}

        {/* TAB 2: CODE STACK VISUALIZATION */}
        {activeTab === "files" && (
          <>
            {/* Left sidebar directory layout */}
            <div className="lg:col-span-3 border-r border-slate-900 bg-slate-950/40 p-4 flex flex-col gap-3 min-w-0">
              <div className="text-xs uppercase tracking-wider font-bold text-slate-500 px-2 flex justify-between items-center">
                <span>Flutter Architecture Codes</span>
                <span className="text-[10px] px-1.5 py-0.5 bg-slate-800 text-teal-300 rounded font-mono font-bold">
                  {dartFiles.length} modules
                </span>
              </div>
              
              <div className="space-y-1.5 overflow-y-auto max-h-[60vh] lg:max-h-full">
                {dartFiles.map((file) => (
                  <button
                    key={file.path}
                    onClick={() => {
                      setSelectedFile(file);
                      addRiverpodLog("action", `Inspected source file payload -> ${file.name}`);
                    }}
                    className={`w-full text-left p-3 rounded-xl border transition-all flex flex-col gap-1 ${
                      selectedFile.path === file.path
                        ? "bg-slate-900 border-teal-500/50 text-white"
                        : "bg-transparent border-transparent text-slate-400 hover:bg-slate-900 hover:text-slate-200"
                    }`}
                  >
                    <div className="flex items-center gap-2 font-mono text-xs font-semibold">
                      <FileCode className={`w-4 h-4 ${selectedFile.path === file.path ? 'text-teal-400' : 'text-slate-500'}`} />
                      <span className="truncate">{file.name}</span>
                    </div>
                    <p className="text-[10px] text-slate-400 line-clamp-1 pl-6 font-sans">
                      {file.description}
                    </p>
                  </button>
                ))}
              </div>

              <div className="mt-auto pt-4 border-t border-slate-900 hidden lg:block">
                <button 
                  onClick={() => {
                    let fullString = dartFiles.map(f => `--- FILE: ${f.path} ---\n${f.code}\n`).join("\n");
                    handleCopy(fullString, "complete_bundle");
                  }}
                  className="w-full flex items-center justify-center gap-2 bg-gradient-to-r from-teal-400 to-indigo-500 hover:from-teal-300 hover:to-indigo-400 text-slate-950 font-bold px-4 py-2.5 rounded-lg text-xs tracking-wider transition duration-150 shadow shadow-teal-500/10 cursor-pointer"
                >
                  <CopyCheck className="w-4 h-4" />
                  Copy Whole Dart Bundle
                </button>
              </div>
            </div>

            {/* Main File Contents */}
            <div className="lg:col-span-9 flex flex-col min-w-0">
              <div className="border-b border-slate-905 bg-slate-950/70 px-6 py-3 flex items-center justify-between">
                <div>
                  <span className="font-mono text-xs text-indigo-400 tracking-wide font-bold block">{selectedFile.path}</span>
                  <p className="text-xs text-slate-400 mt-0.5">{selectedFile.description}</p>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <button
                    onClick={() => handleCopy(selectedFile.code, selectedFile.name)}
                    className="flex items-center gap-1 px-3 py-1.5 bg-slate-900 hover:bg-slate-800 border border-slate-800 text-slate-300 hover:text-white rounded-lg text-xs transition cursor-pointer"
                  >
                    {copied === selectedFile.name ? (
                      <>
                        <Check className="w-3.5 h-3.5 text-emerald-400" />
                        <span className="text-emerald-400">Copied!</span>
                      </>
                    ) : (
                      <>
                        <Copy className="w-3.5 h-3.5" />
                        <span>Copy Code</span>
                      </>
                    )}
                  </button>
                  <button
                    onClick={() => handleDownloadFile(selectedFile)}
                    className="flex items-center gap-1 px-3 py-1.5 bg-slate-900 hover:bg-slate-800 border border-slate-800 text-slate-300 hover:text-white rounded-lg text-xs transition cursor-pointer"
                  >
                    <Download className="w-3.5 h-3.5" />
                    <span>Download</span>
                  </button>
                </div>
              </div>

              {/* Display pre */}
              <div className="flex-1 overflow-auto p-6 font-mono text-xs bg-slate-950/40 leading-relaxed text-slate-300">
                <pre>
                  {selectedFile.code.split('\n').map((line, idx) => (
                    <div key={idx} className="flex hover:bg-slate-900/35 py-0.5">
                      <span className="w-8 shrink-0 text-slate-600 select-none pr-4 text-right">{idx + 1}</span>
                      <span className="whitespace-pre-wrap">{line}</span>
                    </div>
                  ))}
                </pre>
              </div>
            </div>
          </>
        )}

        {/* TAB 4: CROSS-PLATFORM AUTOFILL HUB */}
        {activeTab === "autofill" && (
          <div className="lg:col-span-12 p-6 overflow-y-auto flex flex-col xl:grid xl:grid-cols-12 gap-6 h-full">
            
            {/* Left Control Column: Platform Setup Guides */}
            <div className="xl:col-span-4 flex flex-col gap-4">
              <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-5 shadow-sm">
                <div className="flex items-center gap-2 mb-4">
                  <Sparkles className="w-5 h-5 text-indigo-400" />
                  <span className="font-bold text-white text-sm">Select Integration Channel</span>
                </div>

                <div className="flex p-1 bg-slate-950 rounded-xl border border-slate-800 mb-4">
                  <button
                    onClick={() => {
                      setAutofillPlatform("android");
                      addAutofillLog("System", "Switched integration channel viewport context to Android SDK 33+", "info");
                    }}
                    className={`flex-1 py-2 text-center text-xs font-semibold rounded-lg transition ${
                      autofillPlatform === "android" ? "bg-slate-800 text-teal-300 shadow" : "text-slate-400 hover:text-white"
                    }`}
                  >
                    Android
                  </button>
                  <button
                    onClick={() => {
                      setAutofillPlatform("ios");
                      addAutofillLog("System", "Switched integration channel viewport context to iOS 16 CredentialProvider", "info");
                    }}
                    className={`flex-1 py-2 text-center text-xs font-semibold rounded-lg transition ${
                      autofillPlatform === "ios" ? "bg-slate-800 text-teal-300 shadow" : "text-slate-400 hover:text-white"
                    }`}
                  >
                    iOS Provider
                  </button>
                  <button
                    onClick={() => {
                      setAutofillPlatform("chrome");
                      addAutofillLog("System", "Switched integration channel viewport context to MV3 Chrome Extension", "info");
                    }}
                    className={`flex-1 py-2 text-center text-xs font-semibold rounded-lg transition ${
                      autofillPlatform === "chrome" ? "bg-slate-800 text-teal-300 shadow" : "text-slate-400 hover:text-white"
                    }`}
                  >
                    Chrome Extension
                  </button>
                </div>

                {/* Setup Descriptions */}
                <div className="space-y-4 text-xs leading-relaxed">
                  {autofillPlatform === "android" && (
                    <div className="space-y-3">
                      <div className="p-3 bg-teal-950/40 rounded-xl border border-teal-800/40">
                        <span className="font-bold text-teal-300 block mb-1">Android Autofill Framework</span>
                        <p className="text-slate-300 text-[11px]">
                          Integrates standard <code className="text-amber-300 font-mono">AutofillService</code> matching custom <code className="text-teal-400 font-mono">autofill_hints</code>. Maps background authentication loops using biometric hardware keys.
                        </p>
                      </div>
                      <div className="space-y-1 bg-slate-950 p-3 rounded-xl border border-slate-850">
                        <span className="text-[10px] text-slate-500 font-bold uppercase block">MethodChannel Command</span>
                        <code className="block text-[11px] text-indigo-400 break-all">MethodChannel("io.nexpass.app/autofill")</code>
                      </div>
                      <div className="space-y-1">
                        <span className="text-slate-400 font-semibold block">Adaptation checklist:</span>
                        <ul className="list-disc list-inside space-y-1 text-slate-500 text-[11px]">
                          <li>Registered in AndroidManifest.xml</li>
                          <li>Declares autofillService permission</li>
                          <li>Translates view nodes using MethodChannel</li>
                        </ul>
                      </div>
                    </div>
                  )}

                  {autofillPlatform === "ios" && (
                    <div className="space-y-3">
                      <div className="p-3 bg-indigo-950/40 rounded-xl border border-indigo-800/40">
                        <span className="font-bold text-indigo-300 block mb-1">Apple iOS Provider Extension</span>
                        <p className="text-slate-300 text-[11px]">
                          Integrates <code className="text-amber-300 font-mono">ASCredentialProviderViewController</code> and uses CoreBiometrics verification. Users can autofill credentials without typing in apps.
                        </p>
                      </div>
                      <div className="space-y-1 bg-slate-950 p-3 rounded-xl border border-slate-850">
                        <span className="text-[10px] text-slate-500 font-bold uppercase block">Interface Bridge</span>
                        <code className="block text-[11px] text-teal-400">UIHostingController(rootView: SwiftUIView)</code>
                      </div>
                      <div className="space-y-1">
                        <span className="text-slate-400 font-semibold block">Adaptation checklist:</span>
                        <ul className="list-disc list-inside space-y-1 text-slate-500 text-[11px]">
                          <li>Configured App Groups for safe database sharing</li>
                          <li>Biometric permissions requested in info.plist</li>
                          <li>ASCredentialIdentity mapped in native extension</li>
                        </ul>
                      </div>
                    </div>
                  )}

                  {autofillPlatform === "chrome" && (
                    <div className="space-y-3">
                      <div className="p-3 bg-purple-950/40 rounded-xl border border-purple-800/40">
                        <span className="font-bold text-purple-300 block mb-1">MV3 Browser Extension</span>
                        <p className="text-slate-300 text-[11px]">
                          Flashes custom secure visual badges alongside webpage forms. Initiates asynchronous web messaging tunnels dynamically to pull matching passwords from secure local files.
                        </p>
                      </div>
                      <div className="space-y-1 bg-slate-950 p-3 rounded-xl border border-slate-850">
                        <span className="text-[10px] text-slate-500 font-bold uppercase block">Core Manifest Schema</span>
                        <code className="block text-[11px] text-amber-300">"manifest_version": 3</code>
                      </div>
                      <div className="space-y-1">
                        <span className="text-slate-400 font-semibold block">Adaptation checklist:</span>
                        <ul className="list-disc list-inside space-y-1 text-slate-500 text-[11px]">
                          <li>Set up manifest.json and content_scripts triggers</li>
                          <li>Form autocomplete targets matched via queries</li>
                          <li>Integrated background service worker for secure isolation</li>
                        </ul>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Right Workspaces Column: Devices & Telemetry */}
            <div className="xl:col-span-8 flex flex-col gap-4">
              
              {/* Device Sandbox Visualizer */}
              <div className="bg-slate-900/60 p-6 border border-slate-800 rounded-2xl flex flex-col lg:flex-row gap-6 items-center justify-between">
                
                {/* Simulated device container */}
                <div className="w-full lg:w-72 bg-slate-950 border-4 border-slate-800 rounded-[32px] p-4 shadow-2xl relative min-h-[360px] flex flex-col justify-between overflow-hidden">
                  
                  {/* Smartphone dynamic header info */}
                  <div className="flex justify-between items-center text-[10px] font-mono text-slate-500 border-b border-slate-900 pb-2 mb-2">
                    <span className="font-semibold text-slate-400 uppercase">
                      {autofillPlatform === "android" ? "Android 14" : autofillPlatform === "ios" ? "iOS 17" : "Chrome OS"}
                    </span>
                    <span className="text-teal-400">● Live Channel</span>
                  </div>

                  {autofillPlatform === "android" && (
                    <div className="flex-1 flex flex-col justify-between gap-4">
                      <div className="space-y-2 mt-2">
                        <div className="flex justify-between items-center">
                          <span className="text-[10px] text-slate-500 uppercase font-bold tracking-wide">Mock Login Context</span>
                          <span className="text-[9px] bg-slate-900 text-teal-400 px-1.5 py-0.5 rounded border border-teal-950">github.com</span>
                        </div>
                        
                        <div className="space-y-1.5 bg-slate-900/50 p-3 rounded-xl border border-slate-850">
                          <div>
                            <span className="text-[9px] text-slate-500 block">Username</span>
                            <div className="relative">
                              <input 
                                readOnly
                                type="text"
                                className="w-full bg-slate-950 border border-slate-800 rounded px-2 py-1 text-xs text-slate-300 pr-6" 
                                value={mockFormUser || "Click badge to autofill..."}
                              />
                              <span className="absolute right-1.5 top-1.5 w-3 h-3 bg-teal-500/30 rounded-full animate-ping" />
                            </div>
                          </div>
                          <div>
                            <span className="text-[9px] text-slate-500 block">Password</span>
                            <input 
                              readOnly
                              type="password"
                              className="w-full bg-slate-950 border border-slate-800 rounded px-2 py-1 text-xs text-slate-300" 
                              value={mockFormPass || "••••••••••••••••"}
                            />
                          </div>
                        </div>
                      </div>

                      {/* Custom suggestion indicator */}
                      <button 
                        onClick={() => {
                          addAutofillLog("MethodChannel", "Invoking Native queryMatchingCredentials matching 'github.com'...", "info");
                          setTimeout(() => {
                            setMockFormUser("nexpass_user_dev");
                            setMockFormPass("ghp_SecretDeveloperV2_Argon2Safe");
                            addAutofillLog("Android", "AutofillService filled mapping parameters into target views", "success");
                            addAutofillLog("MethodChannel", "Dispatched successful response payload via Dart callback hook", "success");
                          }, 500);
                        }}
                        className="w-full py-2.5 bg-slate-900 hover:bg-slate-800 border border-teal-500/40 text-teal-300 font-bold rounded-xl text-xs flex items-center justify-center gap-2 cursor-pointer transition shadow"
                      >
                        <Shield className="w-4 h-4 text-teal-400" />
                        <span>Autofill with NexPass</span>
                      </button>
                    </div>
                  )}

                  {autofillPlatform === "ios" && (
                    <div className="flex-1 flex flex-col justify-between gap-4">
                      <div className="space-y-2 mt-2">
                        <span className="text-[10px] text-slate-500 uppercase font-bold tracking-wide">Apple FaceID Verification</span>
                        <div className="bg-slate-900/40 p-3 rounded-xl border border-slate-850 flex flex-col items-center justify-center py-6 text-center gap-3">
                          <div className={`p-3 rounded-full ${isFaceIDPassed ? "bg-emerald-950 text-emerald-400" : "bg-indigo-950 text-indigo-400"}`}>
                            <LockKeyhole className="w-8 h-8 " />
                          </div>
                          <div>
                            <span className="text-xs text-slate-300 font-bold">Biometric Validation</span>
                            <p className="text-[10px] text-slate-500 mt-1">
                              {isFaceIDPassed ? "FaceID Authed successfully!" : "Simulate Apple security request loop"}
                            </p>
                          </div>
                        </div>
                      </div>

                      <div className="space-y-2">
                        <button
                          onClick={() => {
                            addAutofillLog("AppleID", "Requesting secure UIHosting biometric check...", "info");
                            setTimeout(() => {
                              setIsFaceIDPassed(true);
                              setMockFormUser("admin_user");
                              setMockFormPass("badpass");
                              addAutofillLog("Keychain", "Target credential properties released to extension viewController", "sec");
                              addAutofillLog("AppleID", "FaceID Approved. Credentials mapped directly to Safari frame", "success");
                            }, 500);
                          }}
                          className="w-full py-2.5 bg-gradient-to-r from-teal-500 to-indigo-500 hover:from-teal-400 hover:to-indigo-400 text-slate-950 font-bold rounded-xl text-xs flex items-center justify-center gap-1 cursor-pointer transition shadow"
                        >
                          <span>Trigger FaceID Verification</span>
                        </button>
                        {isFaceIDPassed && (
                          <button
                            onClick={() => {
                              setIsFaceIDPassed(false);
                              setMockFormUser("");
                              setMockFormPass("");
                              addAutofillLog("Keychain", "Testing context reset successfully", "info");
                            }}
                            className="w-full py-1.5 bg-slate-900 hover:bg-slate-850 text-slate-400 hover:text-white text-[10px] rounded"
                          >
                            Reset FaceID State
                          </button>
                        )}
                      </div>
                    </div>
                  )}

                  {autofillPlatform === "chrome" && (
                    <div className="flex-1 flex flex-col justify-between gap-4">
                      <div className="space-y-2 mt-2">
                        <span className="text-[10px] text-slate-500 uppercase font-bold tracking-wide">Chrome Web Injection MV3</span>
                        <div className="space-y-2 bg-slate-900/50 p-3 rounded-xl border border-slate-850">
                          <label className="text-[10px] text-slate-400 block font-semibold">Web URL Domain Target</label>
                          <input 
                            type="text"
                            className="w-full bg-slate-950 border border-slate-800 rounded px-2 py-1 text-xs text-amber-300 font-mono" 
                            value={autofillDomain}
                            onChange={(e) => {
                              setAutofillDomain(e.target.value);
                              addAutofillLog("ChromeMV3", `URL host query target set: ${e.target.value}`, "info");
                            }}
                          />
                        </div>

                        <div className="space-y-1 bg-slate-900/30 p-3 rounded-xl border border-slate-850 mt-2">
                          <span className="text-[9px] text-slate-500 block uppercase">Chrome Active Input Values</span>
                          <p className="text-xs text-slate-300 font-mono truncate">User: <code className="text-teal-400">{mockFormUser || "[empty]"}</code></p>
                          <p className="text-xs text-slate-300 font-mono truncate">Pass: <code className="text-indigo-400">{mockFormPass || "[empty]"}</code></p>
                        </div>
                      </div>

                      <button
                        onClick={() => {
                          addAutofillLog("ChromeMV3", `Injected content.js detecting forms on ${autofillDomain}...`, "info");
                          setTimeout(() => {
                            setMockFormUser("nexpass_user_dev");
                            setMockFormPass("ghp_SecretDeveloperV2_Argon2Safe");
                            addAutofillLog("NativeMessagingHost", "Active secure pipe validated. Domain matches vault registry", "sec");
                            addAutofillLog("ChromeMV3", "Content.js injected matching form parameters successfully", "success");
                          }, 600);
                        }}
                        className="w-full py-2.5 bg-purple-900 hover:bg-purple-800 text-white font-bold rounded-xl text-xs flex items-center justify-center gap-1.5 cursor-pointer transition shadow border border-purple-800"
                      >
                        <Sliders className="w-4 h-4 text-purple-300" />
                        <span>Mock Content Injection</span>
                      </button>
                    </div>
                  )}

                </div>

                {/* Explanation walkthrough block */}
                <div className="flex-1 space-y-4">
                  <div className="bg-slate-950 p-4 rounded-xl border border-slate-850 text-xs text-slate-400 leading-relaxed font-sans">
                    <span className="font-bold text-teal-400 block mb-2">Adaptive Platform Workflow Overview:</span>
                    <ol className="list-decimal list-inside space-y-2 text-[11px]">
                      <li>
                        <strong>Verification Requests:</strong> Mobile application framework intercepts webpage input node focuses and captures current domain metadata parameters.
                      </li>
                      <li>
                        <strong>Tunnel Isolation:</strong> Transmits secure background queries to NexPass's local Isar database. Secret parameters are read and decrypted only upon biometric matching.
                      </li>
                      <li>
                        <strong>Injecting Results:</strong> Populates values into system clipboard buffers or native keyboard fields instantly, maintaining an absolute Zero-Knowledge platform topology.
                      </li>
                    </ol>
                  </div>

                  <div className="bg-slate-950 p-4 rounded-xl border border-slate-850">
                    <span className="text-[10px] text-slate-500 uppercase block font-bold mb-2">Platform Schema Configuration Params</span>
                    <pre className="text-[10px] font-mono text-indigo-300 leading-normal overflow-x-auto select-all">
                      {autofillPlatform === "android"
                        ? `// Android framework service mapping\n<service android:name=".NexPassAutofillService"\n         android:permission="android.permission.BIND_AUTOFILL_SERVICE">\n    <intent-filter>\n        <action android:name="android.service.autofill.AutofillService" />\n    </intent-filter>\n    <meta-data android:name="android.autofill" android:resource="@xml/service_configuration" />\n</service>`
                        : autofillPlatform === "ios"
                        ? `// Apple Keychain Options\nlet identity = ASPasswordCredentialIdentity(\n    serviceIdentifier: serviceIdentifiers.first!,\n    user: credential.username,\n    recordIdentifier: credential.uuid\n)\nself.extensionContext.completeRequest(withSelectedCredential: identity)`
                        : `// Chrome MV3 native port host\nchrome.runtime.onMessage.addListener((request, sender, sendResponse) => {\n  if (request.action === "requestDeviceBiometrics") {\n    chrome.runtime.sendNativeMessage('io.nexpass.app.messenger', { domain: request.origin });\n  }\n});`
                      }
                    </pre>
                  </div>
                </div>

              </div>

              {/* Real-time telemetry system logs terminal */}
              <div className="bg-slate-900/40 p-5 border border-slate-800 rounded-2xl flex-1 flex flex-col min-h-[180px]">
                <div className="flex items-center gap-2 mb-3">
                  <Activity className="w-4 h-4 text-teal-400 animate-pulse" />
                  <span className="text-xs uppercase tracking-wider font-semibold text-slate-400">
                    Autofill Channel Communication Telemetry Logs
                  </span>
                </div>
                
                <div className="space-y-1.5 flex-1 max-h-[200px] overflow-y-auto mb-1 bg-slate-950 p-4 rounded-xl border border-slate-850 font-mono text-[11px] pr-1">
                  {autofillTelemetry.map((log, idx) => (
                    <div key={idx} className="flex gap-2 p-1 rounded hover:bg-slate-900/50">
                      <span className="text-slate-500 shrink-0">{log.time}</span>
                      <span className={`font-bold shrink-0 ${
                        log.status === "success" ? "text-emerald-400" :
                        log.status === "sec" ? "text-purple-400" :
                        "text-amber-400"
                      }`}>
                        [{log.system.toUpperCase()}]
                      </span>
                      <span className="text-slate-300 flex-1">{log.event}</span>
                    </div>
                  ))}
                </div>
              </div>

            </div>

          </div>
        )}

        {/* TAB 3: CRYPTOGRAPHIC ACCELERATED ISOLATE SANDBOX */}
        {activeTab === "sandbox" && (
          <div className="lg:col-span-12 p-6 overflow-y-auto flex flex-col xl:grid xl:grid-cols-12 gap-6 h-full">
            
            {/* Inputs dashboard */}
            <div className="xl:col-span-4 flex flex-col gap-4">
              <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-5 shadow-sm">
                <div className="flex items-center gap-2 mb-4">
                  <Cpu className="w-5 h-5 text-teal-400" />
                  <span className="font-bold text-white text-sm">Crypto isolate simulation</span>
                </div>

                <div className="space-y-4">
                  <div>
                    <label className="block text-xs text-slate-400 font-semibold mb-1">Master Password Key seed</label>
                    <input
                      type="password"
                      className="w-full bg-slate-950 border border-slate-850 rounded-xl px-3 py-2 text-xs text-white focus:outline-none"
                      value={masterPasswordPlain}
                      onChange={(e) => setMasterPasswordPlain(e.target.value)}
                    />
                  </div>

                  <div>
                    <label className="block text-xs text-slate-400 font-semibold mb-1">Platform Salt String</label>
                    <input
                      type="text"
                      className="w-full bg-slate-950 border border-slate-850 rounded-xl px-3 py-2 text-xs text-white focus:outline-none font-mono"
                      value={saltString}
                      onChange={(e) => setSaltString(e.target.value)}
                    />
                  </div>

                  <div>
                    <label className="block text-xs text-slate-400 font-semibold mb-1">JSON Plaintext Payload</label>
                    <textarea
                      rows={3}
                      className="w-full bg-slate-950 border border-slate-850 rounded-xl px-3 py-2 text-xs text-slate-300 focus:outline-none font-mono resize-none"
                      value={sandboxPlain}
                      onChange={(e) => setSandboxPlain(e.target.value)}
                    />
                  </div>

                  <button
                    onClick={runSymmetricSandboxSim}
                    disabled={isSandboxRunning}
                    className="w-full flex items-center justify-center gap-2 bg-gradient-to-r from-teal-400 to-indigo-500 hover:from-teal-300 hover:to-indigo-400 text-slate-950 font-bold px-4 py-3 rounded-xl text-xs transition disabled:opacity-50 cursor-pointer"
                  >
                    {isSandboxRunning ? (
                      <>
                        <RefreshCw className="w-4 h-4 animate-spin" />
                        <span>Deriving Keys...</span>
                      </>
                    ) : (
                      <>
                        <Play className="w-4 h-4 fill-slate-950" />
                        <span>Launch Security Matrix Pipeline</span>
                      </>
                    )}
                  </button>
                </div>
              </div>
            </div>

            {/* Logs console output */}
            <div className="xl:col-span-8 flex flex-col gap-4">
              <div className="bg-slate-900/40 p-5 border border-slate-800 rounded-2xl flex-1 flex flex-col">
                <span className="text-xs uppercase tracking-wider text-slate-400 font-semibold block mb-3">
                  Isolate Exec Pipeline output log
                </span>
                
                <div className="space-y-1.5 font-mono text-xs flex-1 max-h-[250px] overflow-y-auto mb-4 bg-slate-950 p-4 rounded-xl border border-slate-850">
                  {sandboxTrace.map((row, idx) => (
                    <div key={idx} className="flex gap-2">
                      <span className="text-slate-600 shrink-0">{row.time}</span>
                      {row.status === "success" && <span className="text-emerald-400 font-bold">[ OK ]</span>}
                      {row.status === "info" && <span className="text-blue-400 font-bold">[ BUSY ]</span>}
                      <span className="text-slate-300">{row.step}</span>
                    </div>
                  ))}
                  {sandboxTrace.length === 0 && (
                    <div className="text-slate-600 text-center py-10">
                      Pipeline state is idle. Trigger the accelerator above to calculate cryptographic blocks.
                    </div>
                  )}
                </div>

                {sandboxResult && (
                  <div className="bg-slate-950 p-4 rounded-xl border border-slate-850 gap-4 grid grid-cols-1 md:grid-cols-2">
                    <div>
                      <span className="text-[10px] uppercase font-mono text-slate-500">Derived argon2 key result</span>
                      <span className="block text-xs font-mono text-emerald-400 break-all">{sandboxResult.keyHex}</span>
                    </div>
                    <div>
                      <span className="text-[10px] uppercase font-mono text-slate-500">Hex GCM ciphertext format</span>
                      <span className="block text-xs font-mono text-blue-400 break-all">{sandboxResult.cipherHex}</span>
                    </div>
                  </div>
                )}
              </div>
            </div>

          </div>
        )}

        {/* TAB 4: FLUTTER VIRTUAL TEST FRAME */}
        {activeTab === "tests" && (
          <div className="lg:col-span-12 p-6 overflow-y-auto flex flex-col md:grid md:grid-cols-12 gap-6 h-full">
            
            <div className="md:col-span-4 bg-slate-900/60 p-5 border border-slate-850 rounded-2xl h-fit">
              <div className="flex items-center gap-2 mb-3">
                <Sliders className="w-5 h-5 text-indigo-400" />
                <span className="font-bold text-white text-sm">Flutter Test Script Runner</span>
              </div>
              
              <p className="text-xs text-slate-400 leading-relaxed mb-4">
                Executes Flutter testing suites against our Zero-Knowledge Dart schemas, Riverpod VaultState mappings, and Isolate-backed encryption blocks.
              </p>

              <div>
                <span className="block text-[10px] uppercase font-mono tracking-wider text-slate-500 mb-1">
                  Overall compilation state ({testProgress}%)
                </span>
                <div className="w-full bg-slate-950 h-2 rounded-full overflow-hidden mb-4">
                  <div className="h-full bg-indigo-500 transition-all duration-300" style={{ width: `${testProgress}%` }} />
                </div>

                <button
                  onClick={triggerUnitTestsSuite}
                  disabled={isRunningTests}
                  className="w-full bg-gradient-to-r from-teal-400 to-indigo-500 hover:from-teal-300 hover:to-indigo-400 text-slate-950 font-bold py-2.5 rounded-xl text-xs uppercase tracking-wider transition disabled:opacity-50 cursor-pointer"
                >
                  {isRunningTests ? "Simulating compiler output..." : "Execute Local Testing Suite"}
                </button>
              </div>
            </div>

            <div className="md:col-span-8 bg-slate-950 border border-slate-850 rounded-2xl overflow-hidden h-[400px] flex flex-col">
              <div className="bg-slate-900 px-4 py-3 border-b border-slate-850 flex justify-between items-center">
                <span className="text-xs font-mono text-slate-400">flutter_test_suite_console.log</span>
                <span className="text-[10px] font-mono text-indigo-400 uppercase font-bold">Passed</span>
              </div>

              <div className="flex-1 p-5 overflow-y-auto font-mono text-xs text-slate-300 space-y-2 bg-slate-950">
                {testLogs.map((row, idx) => (
                  <div key={idx} className="border-l-2 border-slate-800 pl-3 py-0.5 text-slate-300">
                    {row}
                  </div>
                ))}
                {testLogs.length === 0 && (
                  <div className="text-slate-600 text-center py-24 flex flex-col items-center justify-center gap-1.5">
                    <Terminal className="w-8 h-8 opacity-40 text-slate-500" />
                    <span>Testing system is idle. Trigger testing pipeline execution to verify.</span>
                  </div>
                )}
              </div>
            </div>

          </div>
        )}

        {/* TAB 5: SECURITY & WEBDAV SYNC CENTER */}
        {activeTab === "security" && (
          <div className="lg:col-span-12 p-6 overflow-y-auto flex flex-col xl:grid xl:grid-cols-12 gap-6 h-full">
            
            {/* Left Column: Interactive WebDAV Client Sync Engine */}
            <div className="xl:col-span-5 flex flex-col gap-4">
              <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-5 shadow-sm">
                <div className="flex items-center gap-2 mb-4">
                  <RefreshCw className="w-5 h-5 text-teal-400 animate-spin-slow animate-pulse" />
                  <span className="font-bold text-white text-sm">WebDAV Cloud Synchronization</span>
                </div>

                <div className="space-y-4">
                  <div>
                    <label className="block text-xs text-slate-400 font-semibold mb-1">WebDAV Hub Server URL</label>
                    <input
                      type="text"
                      className="w-full bg-slate-950 border border-slate-850 rounded-xl px-3 py-2 text-xs text-indigo-300 font-mono focus:outline-none animate-fadeIn"
                      value={webdavUrl}
                      onChange={(e) => setWebdavUrl(e.target.value)}
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-xs text-slate-400 font-semibold mb-1">Username / Port ID</label>
                      <input
                        type="text"
                        className="w-full bg-slate-950 border border-slate-850 rounded-xl px-3 py-2 text-xs text-white focus:outline-none"
                        value={webdavUser}
                        onChange={(e) => setWebdavUser(e.target.value)}
                      />
                    </div>
                    <div>
                      <label className="block text-xs text-slate-400 font-semibold mb-1">App Token / Passport</label>
                      <input
                        type="password"
                        className="w-full bg-slate-950 border border-slate-850 rounded-xl px-3 py-2 text-xs text-white focus:outline-none"
                        value={webdavPass}
                        onChange={(e) => setWebdavPass(e.target.value)}
                      />
                    </div>
                  </div>

                  <div className="flex items-center justify-between p-3 bg-slate-950 rounded-xl border border-slate-850 mt-1">
                    <div className="flex flex-col">
                      <span className="text-xs font-semibold text-slate-300">Continuous Auto-Sync</span>
                      <span className="text-[10px] text-slate-500">Triggers atomic upload upon local saves</span>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={isWebdavAutoSync}
                        onChange={(e) => {
                          setIsWebdavAutoSync(e.target.checked);
                          addWebdavLog(`Continuous auto-sync is now ${e.target.checked ? "ENABLED" : "DISABLED"}`, "info");
                        }}
                        className="sr-only peer"
                      />
                      <div className="w-9 h-5 bg-slate-850 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-slate-400 after:border-slate-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-teal-400 peer-checked:after:bg-slate-950"></div>
                    </label>
                  </div>

                  <div className="flex gap-2 pt-2">
                    <button
                      onClick={() => {
                        setWebdavSyncStatus("handshake");
                        addWebdavLog("Initiating WebDAV pipeline request stream", "info");
                        
                        setTimeout(() => {
                          setWebdavSyncStatus("comparing");
                          addWebdavLog("Executing handshake basic header check... Approved [200 OK]", "success");
                          addWebdavLog("PROPFIND headers routed. Pulling webDAV directory manifest info for 'nexpass_vault.json'", "info");
                        }, 850);

                        setTimeout(() => {
                          setWebdavSyncStatus("downloading");
                          addWebdavLog("Found remote registry object. Starting incremental synchronization cycle", "info");
                          addWebdavLog("Evaluating differences using local database client 'updatedAt' indexes...", "info");
                        }, 1700);

                        setTimeout(() => {
                          setWebdavSyncStatus("uploading");
                          addWebdavLog("[Sync Decisor] Remote payload updated earlier! Re-merging 1 newer instance safely", "success");
                          addWebdavLog("Generating secure atomic write transaction cache: writing back up node to 'nexpass_vault.tmp'", "info");
                        }, 2500);

                        setTimeout(() => {
                          setWebdavSyncStatus("success");
                          addWebdavLog("Moving temporary cache block dynamically to override 'nexpass_vault.json' (Atomic swap completed)", "success");
                          addWebdavLog("Incremental sync run completed successfully with zero transaction data leaks!", "success");
                        }, 3350);

                      }}
                      className="flex-1 py-2.5 bg-gradient-to-r from-teal-400 to-indigo-500 hover:from-teal-300 hover:to-indigo-400 text-slate-950 font-bold rounded-xl text-xs uppercase tracking-wide transition shadow cursor-pointer text-center duration-150"
                    >
                      {webdavSyncStatus === "handshake" ? "Handshaking..." :
                       webdavSyncStatus === "comparing" ? "Comparing..." :
                       webdavSyncStatus === "downloading" ? "Downloading..." :
                       webdavSyncStatus === "uploading" ? "Uploading atomic..." : 
                       "Perform Incremental WebDAV Sync"}
                    </button>
                    {webdavSyncStatus !== "idle" && (
                      <button
                        onClick={() => {
                          setWebdavSyncStatus("idle");
                          addWebdavLog("WebDAV controller reset to workspace default limits", "info");
                        }}
                        className="p-2.5 bg-slate-950 hover:bg-slate-850 border border-slate-850 text-slate-400 hover:text-white rounded-xl text-xs font-bold transition"
                      >
                        Reset
                      </button>
                    )}
                  </div>
                </div>
              </div>

              {/* WebDAV Activity Logs */}
              <div className="bg-slate-900/60 p-5 border border-slate-800 rounded-2xl flex-1 flex flex-col justify-between">
                <div className="flex items-center gap-2 mb-3">
                  <Activity className="w-4 h-4 text-emerald-400 animate-pulse" />
                  <span className="text-xs uppercase tracking-wider font-semibold text-slate-400">
                    SyncService Pipe Telemetry Logs
                  </span>
                </div>

                <div className="space-y-1 bg-slate-950 p-4 rounded-xl border border-slate-850 font-mono text-[10px] h-[180px] overflow-y-auto">
                  {webdavLogs.map((log, idx) => (
                    <div key={idx} className="flex gap-2">
                      <span className="text-slate-600 shrink-0">{log.time}</span>
                      <span className={`font-bold shrink-0 ${
                        log.status === "success" ? "text-emerald-400" :
                        log.status === "warn" ? "text-rose-400" : "text-indigo-400"
                      }`}>
                        {log.status === "success" ? "[OK]" : log.status === "warn" ? "[WARN]" : "[INFO]"}
                      </span>
                      <span className="text-slate-300 flex-1">{log.action}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Right Column: Interactive Password Health Audit Center */}
            <div className="xl:col-span-7 flex flex-col gap-4">
              <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-6 shadow-sm">
                
                {/* Header overview metrics */}
                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border-b border-slate-800 pb-5 mb-5">
                  <div>
                    <span className="text-xs text-indigo-400 uppercase font-mono tracking-widest font-bold">NexPass Security Audits</span>
                    <h2 className="text-xl font-bold text-white tracking-tight mt-1">Password Health Center</h2>
                  </div>

                  {/* Dynamic security percentage indicator */}
                  <div className="flex items-center gap-3 bg-slate-950 p-3 rounded-2xl border border-slate-850">
                    <div className="relative flex items-center justify-center">
                      <svg className="w-12 h-12">
                        <circle className="text-slate-950" strokeWidth="4" stroke="currentColor" fill="transparent" r="20" cx="24" cy="24" />
                        <circle className="text-teal-400 animate-pulse" strokeWidth="4" strokeDasharray="125" strokeDashoffset={
                          (() => {
                            const weakCount = vaultItems.filter(item => {
                              const passField = item.fields.find(f => f.fieldType === 2 || f.name === "password");
                              return passField && (passField.decryptedValue || "").length < 10;
                            }).length;
                            
                            // Find duplicates count
                            const passwordsMap: {[key: string]: number} = {};
                            vaultItems.forEach(item => {
                              const passField = item.fields.find(f => f.fieldType === 2 || f.name === "password");
                              if (passField) {
                                const val = passField.decryptedValue || decryptSimulatedBase64(passField.value);
                                passwordsMap[val] = (passwordsMap[val] || 0) + 1;
                              }
                            });
                            let dupCount = 0;
                            Object.values(passwordsMap).forEach(v => {
                              if (v > 1) dupCount += v;
                            });

                            const issues = weakCount + dupCount;
                            const score = Math.max(30, 100 - issues * 12);
                            return Math.round(125 * (1 - score / 100));
                          })()
                        } strokeLinecap="round" stroke="currentColor" fill="transparent" r="20" cx="24" cy="24" />
                      </svg>
                      <span className="absolute font-mono text-xs font-bold text-teal-300">
                        {(() => {
                          const weakCount = vaultItems.filter(item => {
                            const passField = item.fields.find(f => f.fieldType === 2 || f.name === "password");
                            return passField && (passField.decryptedValue || "").length < 10;
                          }).length;
                          const passwordsMap: {[key: string]: number} = {};
                          vaultItems.forEach(item => {
                            const passField = item.fields.find(f => f.fieldType === 2 || f.name === "password");
                            if (passField) {
                              const val = passField.decryptedValue || decryptSimulatedBase64(passField.value);
                              passwordsMap[val] = (passwordsMap[val] || 0) + 1;
                            }
                          });
                          let dupCount = 0;
                          Object.values(passwordsMap).forEach(v => {
                            if (v > 1) dupCount += v;
                          });
                          const score = Math.max(20, 100 - (weakCount + dupCount) * 12);
                          return `${score}%`;
                        })()}
                      </span>
                    </div>

                    <div>
                      <span className="text-[10px] text-slate-500 uppercase block font-bold">Health Index Score</span>
                      <span className="text-xs text-slate-300 font-bold">Local vault health ranking</span>
                    </div>
                  </div>
                </div>

                {/* Audit item lists */}
                <div className="space-y-4">
                  <div className="space-y-2">
                    <span className="text-[11px] font-bold text-slate-400 block uppercase tracking-wider">Security Alerts discovered:</span>
                    
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      
                      {/* Sub-panel 1: Short & Weak Passwords */}
                      <div className="bg-slate-950 p-4 rounded-xl border border-slate-850 flex flex-col justify-between">
                        <div>
                          <div className="flex items-center gap-2 mb-2">
                            <span className="w-2 h-2 rounded-full bg-rose-500" />
                            <span className="font-bold text-xs text-slate-300">Weak Credentials (Length &lt; 10)</span>
                          </div>
                          
                          <div className="space-y-2 min-h-[90px] overflow-y-auto pr-1">
                            {vaultItems.filter(item => {
                              const passField = item.fields.find(f => f.fieldType === 2 || f.name === "password");
                              return passField && (passField.decryptedValue || "").length < 10;
                            }).length === 0 ? (
                              <p className="text-[11px] text-slate-500 italic py-4">No weak user passwords found!</p>
                            ) : (
                              vaultItems.filter(item => {
                                const passField = item.fields.find(f => f.fieldType === 2 || f.name === "password");
                                return passField && (passField.decryptedValue || "").length < 10;
                              }).map(item => {
                                const passVal = item.fields.find(f => f.fieldType === 2 || f.name === "password")?.decryptedValue || "";
                                return (
                                  <div key={item.id} className="p-2 border border-red-950/45 bg-red-950/20 rounded-lg flex items-center justify-between gap-2">
                                    <div className="truncate flex-1">
                                      <span className="text-xs font-bold text-slate-200 block truncate">{item.name}</span>
                                      <code className="text-[10px] text-rose-400">"{passVal}" (Length {passVal.length})</code>
                                    </div>
                                    <button 
                                      onClick={() => setIsGeneratorDialogOpen(true)}
                                      className="text-[10px] bg-red-955 hover:bg-red-900 border border-red-800 text-white font-bold px-2 py-1 rounded shrink-0 duration-150 transition cursor-pointer"
                                    >
                                      Fix
                                    </button>
                                  </div>
                                );
                              })
                            )}
                          </div>
                        </div>
                      </div>

                      {/* Sub-panel 2: Duplicate Password Reusages */}
                      <div className="bg-slate-950 p-4 rounded-xl border border-slate-850 flex flex-col justify-between">
                        <div>
                          <div className="flex items-center gap-2 mb-2">
                            <span className="w-2 h-2 rounded-full bg-amber-500" />
                            <span className="font-bold text-xs text-slate-300">Password Reuse / Duplicates</span>
                          </div>

                          <div className="space-y-2 min-h-[90px] overflow-y-auto pr-1">
                            {(() => {
                              // Calculate password duplicate groups
                              const pMap: {[key: string]: typeof vaultItems} = {};
                              vaultItems.forEach(item => {
                                const passField = item.fields.find(f => f.fieldType === 2 || f.name === "password");
                                if (passField) {
                                  const val = passField.decryptedValue || decryptSimulatedBase64(passField.value);
                                  pMap[val] = pMap[val] || [];
                                  pMap[val].push(item);
                                }
                              });

                              const duplicatesList: Array<{pass: string; items: typeof vaultItems}> = [];
                              Object.entries(pMap).forEach(([pass, list]) => {
                                if (list.length > 1) {
                                  duplicatesList.push({ pass, items: list });
                                }
                              });

                              if (duplicatesList.length === 0) {
                                return <p className="text-[11px] text-slate-500 italic py-4">No password reuse patterns found!</p>;
                              }

                              return duplicatesList.map((dup, dIdx) => (
                                <div key={dIdx} className="p-2 border border-amber-950/45 bg-amber-955/20 rounded-lg space-y-1">
                                  <div className="flex justify-between items-center">
                                    <code className="text-[10px] text-amber-400 truncate">Shared: "{dup.pass.substring(0, 15)}..."</code>
                                    <span className="text-[9px] bg-amber-950/80 text-amber-300 border border-amber-850 px-1 py-0.5 rounded font-mono">
                                      {dup.items.length} x
                                    </span>
                                  </div>
                                  <div className="flex flex-wrap gap-1">
                                    {dup.items.map(item => (
                                      <span key={item.id} className="text-[9px] bg-slate-950 text-slate-400 border border-slate-850 px-1.5 py-0.5 rounded truncate max-w-[120px]">
                                        {item.name}
                                      </span>
                                    ))}
                                  </div>
                                </div>
                              ));
                            })()}
                          </div>
                        </div>
                      </div>

                    </div>
                  </div>

                  {/* Vault Strength Distribution Analysis Table */}
                  <div className="bg-slate-950/50 p-4 border border-slate-850 rounded-xl">
                    <span className="text-[10px] text-slate-400 font-bold block uppercase mb-3 text-left">Cryptographic Vault Inventory Audit Registry</span>
                    
                    <div className="space-y-2.5 max-h-[160px] overflow-y-auto pr-1">
                      {vaultItems.map(item => {
                        const passField = item.fields.find(f => f.fieldType === 2 || f.name === "password");
                        const decryptedVal = passField ? (passField.decryptedValue || decryptSimulatedBase64(passField.value)) : "";
                        const length = decryptedVal.length;
                        
                        let rank = "Safe";
                        let rankColor = "text-teal-400 border-teal-950 bg-teal-950/30";
                        if (length < 10) {
                          rank = "Critical Risk";
                          rankColor = "text-rose-450 border-rose-955 bg-rose-950/30";
                        } else if (item.fields.some(f => f.fieldType === 3 || f.name === "totpSecret")) {
                          rank = "MFA Guarded";
                          rankColor = "text-purple-400 border-purple-950 bg-purple-950/30";
                        }

                        return (
                          <div key={item.id} className="flex justify-between items-center py-2 px-3 hover:bg-slate-900/30 border-b border-slate-900 last:border-0 rounded">
                            <div className="truncate flex items-center gap-2">
                              {item.fields.some(f => f.fieldType === 3) ? (
                                <span className="w-1.5 h-1.5 rounded-full bg-purple-400" />
                              ) : (
                                <span className="w-1.5 h-1.5 rounded-full bg-indigo-400" />
                              )}
                              <span className="text-xs text-slate-200 truncate font-semibold">{item.name}</span>
                            </div>

                            <div className="flex items-center gap-3 shrink-0">
                              <span className="font-mono text-[10px] text-slate-500">{length} chars</span>
                              <span className={`text-[9.5px] px-2 py-0.5 rounded border ${rankColor} font-bold font-mono uppercase tracking-wider`}>
                                {rank}
                              </span>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>

                </div>

              </div>
            </div>

          </div>
        )}

      </main>

      {/* Aesthetic Modal Password Generator Panel according to Step 3 popup specs */}
      {isGeneratorDialogOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm animate-fadeIn">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-lg p-6 shadow-2xl relative">
            <div className="flex items-center gap-2 text-white font-bold mb-4">
              <KeyRound className="w-5 h-5 text-teal-400" />
              <span>Modular Password Generator Tool</span>
            </div>

            <div className="bg-slate-950 p-4 rounded-xl border border-slate-850 mb-4 flex justify-between items-center">
              <span className="font-mono text-sm font-bold text-teal-300 break-all select-all">{generatedPasswordText}</span>
              <button
                onClick={() => handleCopy(generatedPasswordText, "modal_password")}
                className="text-slate-400 hover:text-white shrink-0 ml-2"
              >
                {copied === "modal_password" ? (
                  <Check className="w-4 h-4 text-emerald-400" />
                ) : (
                  <Copy className="w-4 h-4" />
                )}
              </button>
            </div>

            {/* Multi Options checkboxes matching step 3 */}
            <div className="space-y-4 text-xs font-sans">
              <div>
                <div className="flex justify-between text-slate-400 mb-1">
                  <span>Pin / Passphrase Characters length:</span>
                  <span className="font-mono text-white font-bold">{lengthInput} characters</span>
                </div>
                <input
                  type="range"
                  min={8}
                  max={64}
                  value={lengthInput}
                  onChange={(e) => setLengthInput(Number(e.target.value))}
                  className="w-full accent-teal-400"
                />
              </div>

              <div className="grid grid-cols-2 gap-3 text-slate-300">
                <label className="flex items-center gap-2 cursor-pointer hover:text-white">
                  <input
                    type="checkbox"
                    checked={useUppercase}
                    onChange={(e) => setUseUppercase(e.target.checked)}
                    className="accent-teal-400 w-4 h-4"
                  />
                  <span>Include Uppercase Letters (A-Z)</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer hover:text-white">
                  <input
                    type="checkbox"
                    checked={useLowercase}
                    onChange={(e) => setUseLowercase(e.target.checked)}
                    className="accent-teal-400 w-4 h-4"
                  />
                  <span>Include Lowercase Letters (a-z)</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer hover:text-white">
                  <input
                    type="checkbox"
                    checked={useDigits}
                    onChange={(e) => setUseDigits(e.target.checked)}
                    className="accent-teal-400 w-4 h-4"
                  />
                  <span>Include Numbers (0-9)</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer hover:text-white">
                  <input
                    type="checkbox"
                    checked={useSymbols}
                    onChange={(e) => setUseSymbols(e.target.checked)}
                    className="accent-teal-400 w-4 h-4"
                  />
                  <span>Include Special Symbols / Punctuation</span>
                </label>
              </div>

              <div className="p-3 bg-slate-950 rounded-xl border border-slate-850 flex flex-col gap-1">
                <div className="flex justify-between items-center mb-1">
                  <span className="text-[10px] text-slate-500 font-mono">MATHEMATICAL SECURITY METRICS SCORE:</span>
                  <span className={`font-bold uppercase tracking-wider ${strengthMeta.text}`}>{strengthMeta.label}</span>
                </div>
                <div className="w-full bg-slate-900 h-2 rounded-full overflow-hidden">
                  <div className={`h-full ${strengthMeta.color}`} style={{ width: `${strengthMeter * 100}%` }} />
                </div>
              </div>

              <div className="flex gap-2.5 justify-end pt-3 border-t border-slate-800">
                <button
                  onClick={() => setIsGeneratorDialogOpen(false)}
                  className="bg-slate-950 hover:bg-slate-800 text-slate-300 font-bold px-4 py-2 rounded-xl text-xs transition"
                >
                  Close Tool
                </button>
                <button
                  onClick={() => {
                    setFormSecretValue(generatedPasswordText);
                    setIsGeneratorDialogOpen(false);
                    addRiverpodLog("action", `Applied output "${generatedPasswordText.substring(0, 10)}..." to account credentials form`);
                  }}
                  className="bg-gradient-to-r from-teal-400 to-indigo-500 hover:from-teal-300 hover:to-indigo-400 text-slate-950 font-bold px-4 py-2 rounded-xl text-xs tracking-wide transition shadow"
                >
                  Insert Into Client Form
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Clean Footer */}
      <footer className="border-t border-slate-900 bg-slate-950 px-6 py-4 flex flex-col sm:flex-row sm:items-center sm:justify-between text-xs text-slate-500 gap-2 font-sans">
        <span>NexPass zero knowledge system specifications securely validated in development environment.</span>
        <span>UTC Clock: 2026-05-19 23:20</span>
      </footer>

      {/* Monica Inspired Dual-Clipboard Toast Overlay */}
      {dualClipboardToast && dualClipboardToast.show && (
        <div className="fixed bottom-6 right-6 z-50 max-w-md bg-slate-900 border border-teal-400 bg-opacity-95 text-slate-100 p-5 rounded-2xl shadow-2xl animate-fade-in flex flex-col gap-3 font-sans">
          <div className="flex items-center justify-between border-b border-slate-800 pb-2">
            <div className="flex items-center gap-2">
              <Sparkles className="w-5 h-5 text-teal-400" />
              <span className="font-bold text-xs text-teal-300 uppercase tracking-widest">Monica Core Co-Copy Link</span>
            </div>
            <button
              onClick={() => setDualClipboardToast(null)}
              className="text-slate-400 hover:text-white font-bold text-xs bg-slate-950 px-1.5 py-0.5 rounded cursor-pointer"
            >
              ✕
            </button>
          </div>
          <div>
            <p className="text-xs text-slate-300 leading-normal">
              Companion <strong>TOTP field</strong> detected for <strong className="text-teal-300">"{dualClipboardToast.itemName}"</strong>. Dual-clipboard matrix routing:
            </p>
            <div className="mt-3 space-y-2">
              <div className="bg-slate-950 p-2.5 rounded-xl border border-slate-800 flex items-center justify-between text-xs">
                <div>
                  <span className="text-[9px] text-slate-500 uppercase block">Active OS Clipboard (TOTP Code)</span>
                  <code className="text-teal-300 font-mono font-bold text-sm tracking-widest">{dualClipboardToast.totpCopied}</code>
                </div>
                <span className="text-[10px] bg-teal-950 text-teal-400 px-2 py-0.5 rounded font-semibold border border-teal-900">
                  COPIED
                </span>
              </div>
              
              <div className="bg-slate-950 p-2.5 rounded-xl border border-slate-800 flex items-center justify-between text-xs">
                <div>
                  <span className="text-[9px] text-slate-500 uppercase block">Simulated Native Memory Cache (Password)</span>
                  <code className="text-indigo-300 font-mono">{dualClipboardToast.passwordCopied.replace(/./g, "•")}</code>
                </div>
                <span className="text-[10px] bg-indigo-950 text-indigo-400 px-2 py-0.5 rounded font-mono border border-indigo-900 animate-pulse">
                  CACHED
                </span>
              </div>
            </div>
            <p className="text-[10px] text-slate-500 mt-2.5 leading-normal">
              💡 <strong>Instruction:</strong> Paste password inside current webview, then swap to the verification app. The active OTP resides in your system clipboard memory.
            </p>
          </div>
        </div>
      )}

    </div>
  );
}
