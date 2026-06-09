# 📘 توثيق النظام — تطبيق إدارة الموارد البشرية (GRH) والشاتبوت

> **اللغة:** تونسي (دارجة)  
> **المشروع:** STB Gestion RH — منصة داخلية لإدارة الموارد البشرية في Société Tunisienne de Banque  
> **آخر تحديث:** جوان 2026

---

## 1. شنوّا هاذي المنصة؟

هاذي **منصة GRH** (Gestion des Ressources Humaines) — يعني **نظام إدارة الموارد البشرية** — مصمّمة باش تسهّل الخدمة بين:

- **الموظّفين** (employés)
- **فريق الموارد البشرية** (RH)
- **الإدارة** (admin)

الهدف الأساسي: **رقمنة** كل ما يخص HR — الإجازات، الغيابات، التأخيرات، القروض، الحضور، الإشعارات، والوثائق — ومعاه **مساعد ذكي (Chatbot)** يساعد الموظّف يفهم وضعيته ويطلب خدماته بالمحادثة.

المنصة مكوّنة من **جزئين كبار:**

| الجزء | التكنولوجيا | الدور |
|-------|-------------|-------|
| **التطبيق** | Flutter (Dart) | واجهة المستخدم — موبايل / ويب |
| **السيرفر** | PHP + MySQL | API REST + قاعدة البيانات |
| **الشاتبوت** | Google Gemini AI | مساعد HR ذكي |

---

## 2. البنية العامة — كيفاش يتصلّو ببعضهم

```
┌─────────────────────────────────────────────────────────┐
│              تطبيق Flutter (gestion_rh/)                │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │  Login   │  │ Dashboard│  │  Chatbot Widget      │  │
│  │  Screens │  │  par rôle│  │  (مساعد HR)          │  │
│  └────┬─────┘  └────┬─────┘  └──────────┬───────────┘  │
│       │             │                    │              │
│       └─────────────┴────────────────────┘              │
│                     │                                   │
│              ApiService + AuthService                     │
│              (HTTP + Token Bearer)                      │
└─────────────────────┼───────────────────────────────────┘
                      │  REST JSON
                      ▼
┌─────────────────────────────────────────────────────────┐
│           API PHP (gestion_rh_api/)                       │
│  auth/  conges/  absences/  retards/  credits/          │
│  employees/  notifications/  pointages/  chatbot/       │
└─────────────────────┬───────────────────────────────────┘
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
   ┌─────────────┐        ┌──────────────┐
   │  MySQL DB   │        │ Google Gemini│
   │ gestion_rh  │        │     API      │
   └─────────────┘        └──────────────┘
```

**باختصار:** التطبيق يبعث طلبات HTTP للـ API. الـ API يقرا/يكتب في MySQL. الشاتبوت يقرا بيانات HR الحقيقية من DB ويبعثها لـ Gemini باش يجاوب الموظّف.

---

## 3. الأدوار (Roles) — شكون يشوف شنوّا

النظام فيه **3 أدوار** رئيسية:

### 👤 الموظّف (`employee`)
- يشوف **dashboard** خاصّ فيه (إحصائيات، غيابات، تأخيرات)
- يطلب **congés** (إجازات)
- يطلب **crédits** (قروض / سلف على الراتب)
- يعمل **pointage** (تسجيل حضور قبل 10:00)
- يستعمل **الشاتبوت** (زر FAB في الصفحة الرئيسية)
- يقرا **notifications** و **documents**

### 🏢 الموارد البشرية (`rh`)
- يوافق أو يرفض طلبات الإجازات والقروض
- يسجّل **absences** (غيابات) و **retards** (تأخيرات)
- يدير **pointages** (التحقق من الحضور)
- يشوف **liste employés** و **statistiques** عامّة
- يضيف **documents** رسمية
- **ما عندوش** شاتبوت في الواجهة (الشاتبوت للموظّفين)

### ⚙️ الإدارة (`admin`)
- يدير **المستخدمين** (إنشاء، تعديل، حذف)
- يشوف **statistiques** عامّة للمؤسسة
- **ما عندوش** شاتبوت

**بعد login:** التطبيق يوجّهك تلقائياً حسب `role` → `EmployeeHome` / `RHHome` / `AdminHome`.

---

## 4. تطبيق GRH — الوحدات والخدمات

### 4.1 🔐 المصادقة (Authentication)

**كيفاش تدخل:**

1. تفتح التطبيق → **Splash Screen** (~3 ثواني)
2. إذا عندك **token** محفوظ → تدخل مباشرة
3. ولا → **Login** بـ **matricule** + **mot de passe**
4. الـ API (`auth/login.php`) يرجّع **token** صالح **7 أيام**
5. Token يتحفظ في `SharedPreferences` (التطبيق)

**مثال حسابات تجريبية** (من قاعدة البيانات):
- `EMP001` — موظّف
- `RH001` — RH
- `ADM001` — admin  
- Mot de passe par défaut: `password`

---

### 4.2 🏖️ إدارة الإجازات (Congés)

| الميزة | التفاصيل |
|--------|----------|
| **Solde congé** | محفوظ بالساعات (24h = 1 jour) في `users.solde_conge` |
| **Allocation annuelle** | +720h كل سنة (30 jours), plafond 1440h (60 jours) |
| **Types** | payé, maladie, sans solde, etc. |
| **Workflow** | employé يطلب → RH يوافق/يرفض → solde ينقص تلقائياً |
| **Vérifications** | ما ينجمش يطلب أكثر من solde; ما ينجمش dates متداخلة |

**Endpoints:**
- `conges/create.php` — طلب جديد
- `conges/my_conges.php` — إجازاتي
- `conges/list.php` — كل الطلبات (RH)
- `conges/update_status.php` — موافقة/رفض
- `conges/allocate_yearly.php` — توزيع سنوي

---

### 4.3 💰 القروض والسلف (Crédits)

- الموظّف يطلب **crédit** (montant, durée, motif)
- **Taux d'intérêt:** 7.5%
- **Eligibility:** قواعد في `check_eligibility.php` (ancienneté, solde, etc.)
- RH يوافق أو يرفض
- **ملاحظة:** ما فيش module **paie** (راتب) — القروض هي "avances sur salaire"

---

### 4.4 🕒 الغيابات والتأخيرات (Absences & Retards)

| Module | الوصف |
|--------|-------|
| **Absences** | غياب يوم كامل — justifiée أو non justifiée |
| **Retards** | تأخير في الوصول — **5 retards = −1 jour congé** (سياسة STB) |
| **Pointages** | تسجيل حضور رقمي قبل 10:00 — يولّد retards/absences تلقائياً |

**RH** يسجّل absences/retards يدوياً أو يتحقّق من pointages.

---

### 4.5 🔔 الإشعارات (Notifications)

- Types: `conge`, `absence`, `retard`, `credit`, `system`, `message`
- Badge أحمر على الأيقونة
- تختفي badge بعد **mark as read**

---

### 4.6 📄 الوثائق (Documents)

- روابط لوثائق رسمية STB
- RH يضيف، الموظّف يقرا

---

### 4.7 📊 Dashboard & Statistiques

- **Employé:** KPIs شخصية، charts (absences, retards, congés)
- **RH/Admin:** statistiques عامّة، répartition par département

---

## 5. الشاتبوت (Chatbot) — كيفاش يخدم

### 5.1 شنوّا هو؟

**RH Assistant** — مساعد HR ذكي مدمج في التطبيق. الموظّف يسألو بالمحادثة على:

- solde congé متاعو
- حالة طلبات الإجازات والقروض
- كيفاش يطلب congé أو crédit
- سياسات HR (إجازات، غيابات، تأخيرات)
- **ويمكن ينفّذ actions** مباشرة (يطلب congé، crédit، justification)

**الشاتبوت متاح للموظّفين فقط** — زر FAB في `EmployeeHome`.

---

### 5.2 مسار الرسالة (Message Flow)

```
الموظّف يكتب رسالة
        │
        ▼
ChatbotWidget (Flutter)
  • يحفظ history في SharedPreferences
  • POST → chatbot/chat.php + Bearer token
        │
        ▼
chat.php (Backend)
  1. يتحقّق من المستخدم (getAuthUser)
  2. يجيب history (DB أو من client)
  3. يجيب CONTEXT من MySQL:
     • solde congé
     • آخر congés, absences, retards, crédits
     • (لـ RH: liste employés + stats)
  4. يبني system prompt (HR_Chatbot_System_Prompt.md + context)
  5. يبعث لـ Google Gemini API
  6. يقرا الرد — إذا فيه ACTION tags → ينفّذ في DB
  7. يرجّع { response, action_executed }
        │
        ▼
ChatbotWidget يعرض الرد ويحفظ locally
```

---

### 5.3 الذكاء الاصطناعي — Google Gemini

| العنصر | التفاصيل |
|--------|----------|
| **Provider** | Google Gemini (`generativelanguage.googleapis.com`) |
| **Modèle** | Auto-sélection: `gemini-2.5-flash`, `gemini-2.0-flash`, etc. |
| **Knowledge base** | **ما فيش** vector DB — المعرفة = prompt + données DB live |
| **System prompt** | `HR_Chatbot_System_Prompt.md` — شخصية RH Assistant، قواعد، intents |

**مهم:** الشاتبوت **ما يخترعش** بيانات — يقرا من DB الحقيقية ويحقنها في context قبل ما يبعث لـ Gemini.

---

### 5.4 Actions قابلة للتنفيذ

الشاتبوت يقدر **ينفّذ actions** في قاعدة البيانات عبر tags في رد Gemini:

| Tag | من يستعمل | التأثير |
|-----|-----------|---------|
| `[ACTION:CREATE_CONGE:{...}]` | Employé | INSERT في `conges` |
| `[ACTION:CREATE_CREDIT:{...}]` | Employé | INSERT في `crédits` |
| `[ACTION:JUSTIFY_ABSENCE:{...}]` | Employé | UPDATE `absences.motif` |
| `[ACTION:CREATE_ABSENCE:{...}]` | RH | INSERT absence لموظّف |
| `[ACTION:CREATE_RETARD:{...}]` | RH | INSERT retard + notification |

**مثال:** الموظّف يقول "bghiti congé men 10 l 15 mars" → الشاتبوت يجمع التفاصيل → يرجّع tag → `chat.php` ينشئ الطلب في DB.

---

### 5.5 History المحادثة

- **Client-side:** `SharedPreferences` — key `chatbot_history_{userId}`
- **Server-side (optionnel):** table `chatbot_history` — إذا موجودة (setup via `setup_history.php`)

Flutter يبعث history مع كل message؛ الـ API يستعمل DB إذا table موجودة.

---

### 5.6 اللغة

الشاتبوت **يتكلم بلغة المستخدم** — فرançais, arabe, ou derja. الـ prompt يطلب "Match their language automatically."

---

## 6. قاعدة البيانات (MySQL)

### الجداول الرئيسية

| Table | الغرض |
|-------|-------|
| `users` | الموظّفين + RH + admin — auth, solde_conge, role |
| `conges` | طلبات الإجازات |
| `absences` | الغيابات |
| `retards` | التأخيرات |
| `credits` | طلبات القروض |
| `notifications` | الإشعارات |
| `documents` | الوثائق الرسمية |
| `pointages` | تسجيل الحضور (migration) |
| `chatbot_history` | history الشاتبوت (optionnel) |

**Schema:** `gestion_rh_api/gestion_rh.sql`

---

## 7. API — هيكلة Endpoints

كل endpoint = **ملف PHP واحد** — JSON in/out, CORS enabled.

```
gestion_rh_api/
├── auth/           login, verify_token
├── employees/      list, read, create, update, delete
├── conges/         list, create, my_conges, update_status, allocate_yearly
├── absences/       list, create, my_absences
├── retards/        list, create, my_retards
├── credits/        list, create, my_credits, update_status, check_eligibility
├── notifications/  list, create, mark_read
├── dashboard/      stats
├── documents/      list, create
├── pointages/      create, list, verify, generate_absences
└── chatbot/        chat, setup_history
```

**Response typique:**
```json
{
  "success": true,
  "message": "...",
  "data": { ... }
}
```

**Auth:** Header `Authorization: Bearer <token>`

---

## 8. الملفات المهمة

### Flutter (`gestion_rh/`)

| الملف | الدور |
|-------|-------|
| `lib/main.dart` | Point d'entrée |
| `lib/config/api_config.dart` | URLs الـ API |
| `lib/services/auth_service.dart` | Login, token, cache |
| `lib/services/api_service.dart` | HTTP requests |
| `lib/widgets/chatbot_widget.dart` | واجهة الشاتبوت |
| `lib/screens/employee/employee_home.dart` | Dashboard employé + FAB chatbot |
| `lib/screens/rh/rh_home.dart` | Dashboard RH |
| `lib/screens/admin/admin_home.dart` | Dashboard admin |

### PHP API (`gestion_rh_api/`)

| الملف | الدور |
|-------|-------|
| `config/db_connect.php` | Connexion MySQL |
| `chatbot/chat.php` | **قلب الشاتبوت** — Gemini + actions |
| `auth/login.php` | Authentification |
| `conges/create.php`, `update_status.php` | Congés |
| `credits/check_eligibility.php` | Eligibility crédits |

### Documentation

| الملف | الدور |
|-------|-------|
| `Documentation_Projet.md` | Doc française |
| `HR_Chatbot_System_Prompt.md` | Prompt الشاتبوت |
| `Documentation_Systeme_Derja.md` | **هاذي الوثيقة** |

---

## 9. التثبيت والتشغيل

### 9.1 Backend (XAMPP)

1. شغّل **Apache** + **MySQL**
2. Import `gestion_rh.sql` في phpMyAdmin
3. Copie `gestion_rh_api/` في `htdocs/Gestion_RH1/gestion_rh_api`
4. (Optionnel) Run `upgrade_smart_attendance.php` — pointages
5. (Optionnel) Run `chatbot/setup_history.php` — history serveur
6. Configure **Gemini API key** في `chatbot/chat.php`

**Config DB** (`config/db_connect.php`):
```php
$host = "localhost";
$db_name = "gestion_rh";
$username = "root";
$password = "";
```

### 9.2 Flutter App

1. `cd gestion_rh`
2. عدّل `lib/config/api_config.dart` — **base URL** (IP PC + path Apache)
   - Web: `http://localhost/Gestion_RH1/gestion_rh_api`
   - Mobile: `http://192.168.x.x/Gestion_RH1/gestion_rh_api`
3. `flutter run`

---

## 10. ملخص سريع — شنوّا يخدم وشنوّا لا

| ✅ موجود | ❌ غير موجود / جزئي |
|----------|---------------------|
| Congés, absences, retards | Paie (راتب) |
| Crédits / avances | Messaging interne (table موجودة، API/UI لا) |
| Pointages, notifications | ML `get_acceptance_probability` (prompt فقط) |
| Chatbot Gemini + actions DB | Vector knowledge base |
| 3 rôles (admin, rh, employee) | Policy DB منفصلة |

---

## 11. مخطط تدفق المستخدم (Employé)

```
Login (matricule + password)
        │
        ▼
EmployeeHome
  ├── Dashboard (stats, charts)
  ├── Pointage (avant 10:00)
  ├── Congés → create / my_conges
  ├── Crédits → create / my_credits
  ├── Notifications
  ├── Documents
  ├── Profile
  └── [FAB] Chatbot → أسئلة + actions (congé, crédit, justification)
```

---

## 12. أسئلة شائعة (FAQ)

**س: الشاتبوت يقدر يغيّر solde congé مباشرة؟**  
ج: لا — solde يتغيّر فقط عند **approbation** congé من RH أو allocation annuelle.

**س: RH يستعمل الشاتبوت؟**  
ج: الشاتبوت في واجهة **Employé** فقط. RH عندو context إضافي في prompt إذا استعمل API مباشرة.

**س: وين history الشاتبوت؟**  
ج: أساساً في **التطبيق** (SharedPreferences). Serveur يحفظ إذا table `chatbot_history` موجودة.

**س: كيفاش الشاتبوت يعرف solde متاعي؟**  
ج: `chat.php` يقرا `users.solde_conge` و congés/absences/credits من DB ويحقنهم في context قبل Gemini.

---

*وثيقة مكتوبة بالدارجة التونسية — للفريق التقني والمستخدمين.*
