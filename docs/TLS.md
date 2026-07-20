---
icon: lucide/lock-keyhole
---

# :lucide-lock-keyhole: Protocolul TLS

TLS (Transport Layer Security) este un protocol criptografic care asigură confidențialitatea și integritatea datelor transmise între client și server. Este succesorul protocolului SSL (Secure Sockets Layer) și stă la baza HTTPS, dar și a altor protocoale securizate precum SMTPS, FTPS sau VPN-urilor bazate pe TLS.

## De ce avem nevoie de TLS?

Fără un protocol de securitate, traficul de rețea circulă în clar și poate fi citit sau modificat de oricine se află pe drumul dintre client și server (de exemplu, un atacator aflat în aceeași rețea Wi-Fi). TLS rezolvă trei probleme fundamentale:

- **Confidențialitate** — datele sunt criptate, astfel încât un atacator care interceptează traficul nu poate citi conținutul.
- **Integritate** — orice modificare a datelor în tranzit este detectată printr-un cod de autentificare a mesajului (MAC) sau printr-un mod criptografic autentificat (AEAD).
- **Autentificare** — clientul poate verifica identitatea serverului (și opțional, invers) folosind certificate digitale semnate de o autoritate de certificare.

!!! note "TLS nu este o soluție universală"
    TLS protejează datele **în tranzit**. Nu protejează datele stocate pe disc, nu previne atacurile de tip phishing și nu garantează că serverul cu care vorbești este de încredere — doar că este cel care pretinde a fi.

## Poziția TLS în stiva de rețea

TLS se situează între stratul de transport (TCP) și protocoalele de aplicație (HTTP, SMTP, FTP etc.), oferind un canal securizat peste care acestea pot rula neschimbate.

```mermaid
graph TD
    A["Aplicație (HTTP, SMTP, FTP...)"] --> B["TLS — criptare, integritate, autentificare"]
    B --> C["TCP — transport fiabil"]
    C --> D["IP — rutare pachete"]
    D --> E["Strat fizic / legătură de date"]
```

## Istoricul protocolului

| Versiune | An | Status |
|---|---|---|
| SSL 2.0 | 1995 | Nesigur, interzis |
| SSL 3.0 | 1996 | Nesigur, interzis (vulnerabil la POODLE) |
| TLS 1.0 | 1999 | Depreciat |
| TLS 1.1 | 2006 | Depreciat |
| TLS 1.2 | 2008 | Încă folosit pe scară largă |
| TLS 1.3 | 2018 | Recomandat, standard actual |

TLS 1.3 simplifică semnificativ protocolul: elimină algoritmii criptografici slabi, reduce handshake-ul la un singur drum-întors (**1-RTT**) și introduce modul **0-RTT** pentru reconectări rapide.

## Componente cheie

- **Certificat digital (X.509)** — conține cheia publică a serverului și identitatea acestuia, semnate digital.
- **Autoritate de certificare (CA)** — o entitate de încredere care semnează certificatele și le validează identitatea.
- **Chei asimetrice** — o pereche cheie publică / cheie privată, folosită la începutul conexiunii pentru autentificare și schimb de chei.
- **Chei simetrice de sesiune** — generate în timpul handshake-ului, folosite pentru a cripta efectiv datele, deoarece criptarea simetrică este mult mai rapidă decât cea asimetrică.
- **MAC / AEAD** — mecanisme care garantează integritatea și autenticitatea datelor (de exemplu, AES-GCM combină criptarea și autentificarea într-un singur pas).

## Lanțul de încredere (certificate chain)

Un certificat de server nu este verificat izolat, ci printr-un lanț de semnături care urcă până la o autoritate rădăcină în care sistemul de operare sau browserul are deja încredere.

```mermaid
graph TD
    Root["Autoritate rădăcină (Root CA)<br/>de încredere în sistemul de operare"] --> Intermediate["Autoritate intermediară (Intermediate CA)"]
    Intermediate --> Leaf["Certificat server<br/>(ex: exemplu.ro)"]
```

## Handshake-ul TLS 1.2

Handshake-ul TLS 1.2 necesită **două drumuri-întoarse (2-RTT)** înainte ca datele aplicației să poată fi trimise.

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server

    C->>S: ClientHello (versiuni suportate, cipher suites, random)
    S->>C: ServerHello (versiune aleasă, cipher suite, random)
    S->>C: Certificate (certificat + cheie publică)
    S->>C: ServerHelloDone
    C->>S: ClientKeyExchange (schimb de chei / premaster secret)
    C->>S: ChangeCipherSpec
    C->>S: Finished (criptat)
    S->>C: ChangeCipherSpec
    S->>C: Finished (criptat)
    Note over C,S: Ambele părți derivă cheia de sesiune<br/>și pot trimite date aplicație criptate
```

## Handshake-ul TLS 1.3

TLS 1.3 reduce handshake-ul la **un singur drum-întors (1-RTT)**, deoarece clientul trimite ghicit cheile de schimb (key share) odată cu primul mesaj.

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server

    C->>S: ClientHello + key share (ghicire algoritm)
    S->>C: ServerHello + key share
    S->>C: EncryptedExtensions, Certificate, CertificateVerify, Finished
    C->>S: Finished
    Note over C,S: Date aplicație criptate<br/>pot fi trimise imediat după Finished
```

!!! tip "0-RTT"
    Pentru reconectări la un server contactat anterior, TLS 1.3 permite modul **0-RTT**, în care clientul trimite date aplicație chiar în primul mesaj, folosind o cheie derivată dintr-o sesiune anterioară. Avantajul este viteza; dezavantajul este riscul de atacuri de tip *replay*.

## Record Protocol

După finalizarea handshake-ului, toate datele circulă prin **TLS Record Protocol**, care le împarte în fragmente, le criptează și le atașează un cod de autentificare.

```mermaid
graph LR
    A["Date aplicație"] --> B["Fragmentare"]
    B --> C["Criptare + MAC/AEAD"]
    C --> D["Antet TLS Record"]
    D --> E["Trimis prin TCP"]
```

## Cipher suites

O cipher suite descrie combinația de algoritmi folosiți într-o conexiune. De exemplu:

```
TLS_AES_256_GCM_SHA384
```

| Componentă | Rol |
|---|---|
| `TLS` | Protocolul |
| `AES_256_GCM` | Algoritm de criptare simetrică (AES, cheie de 256 biți, mod AEAD GCM) |
| `SHA384` | Funcție hash folosită pentru derivarea cheilor (HKDF) |

În TLS 1.3, algoritmul de schimb de chei (ex: ECDHE) și cel de semnătură (ex: RSA sau ECDSA) sunt negociate separat, spre deosebire de TLS 1.2, unde erau incluse în numele cipher suite-ului (ex: `TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384`).

## Vulnerabilități istorice notabile

| Nume | An | Descriere pe scurt |
|---|---|---|
| **Heartbleed** | 2014 | Bug în OpenSSL (extensia Heartbeat) ce permitea citirea memoriei serverului. |
| **POODLE** | 2014 | Exploata o slăbiciune din SSL 3.0 pentru a decripta parțial traficul. |
| **BEAST** | 2011 | Ataca modul CBC din TLS 1.0. |
| **FREAK / Logjam** | 2015 | Forțau folosirea unor chei criptografice slabe ("export-grade"). |

Aceste vulnerabilități au motivat direct simplificarea și întărirea protocolului în TLS 1.3, care elimină complet algoritmii vulnerabili (RC4, CBC static, compresie etc.).

## Verificare practică cu OpenSSL

Poți inspecta conexiunea TLS a unui server direct din linia de comandă:

```bash
# Afișează detalii despre handshake și certificatul serverului
openssl s_client -connect exemplu.ro:443 -tls1_3

# Verifică ce versiuni TLS suportă un server
nmap --script ssl-enum-ciphers -p 443 exemplu.ro
```

## Rezumat

- TLS asigură **confidențialitate**, **integritate** și **autentificare** pentru datele în tranzit.
- Folosește criptografie **asimetrică** pentru handshake și **simetrică** pentru transferul efectiv de date.
- **TLS 1.3** este versiunea recomandată astăzi: handshake mai rapid (1-RTT), fără algoritmi vulnerabili.
- Securitatea depinde de un **lanț de încredere** validat prin certificate semnate de autorități de certificare recunoscute.
- Versiunile **SSL** și **TLS 1.0/1.1** sunt considerate nesigure și nu ar trebui folosite.
