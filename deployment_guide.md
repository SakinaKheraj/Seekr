# 🚀 Complete Guide: GitHub & AWS Deployment

This guide will walk you through pushing your project to GitHub and then deploying the backend to a live AWS server so your app works anywhere!

---

## 📂 Part 1: Pushing your Code to GitHub

Since you have secrets (like `.env` and `firebase_cred.json`), we must ensure they are safe.

### 1. Initialize Git
Open your terminal in the root folder (`c:\Flutter\seekr`) and run:
```bash
git init
```

### 2. Verify `.gitignore`
Make sure you have a `.gitignore` file in your root folder. It should include:
- `venv/`
- `.env`
- `firebase_cred.json`
- `build/`
- `.dart_tool/`
*(If you don't have these in your .gitignore, let me know and I will add them for you!)*

### 3. Commit and Push
1. Create a new repository on [GitHub](https://github.com/new). Do **not** initialize with a README.
2. Run these commands:
```bash
git add .
git commit -m "feat: Add Docker infrastructure and AWS cloud support"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git push -u origin main
```

---

## ☁️ Part 2: Deploying the Backend to AWS EC2

### 1. Launch the Instance
1. Log into your **AWS Management Console**.
2. Search for **EC2** and click **Launch Instance**.
3. **Name**: `seekr-backend`.
4. **OS**: Choose **Ubuntu 24.04 LTS**.
5. **Instance Type**: `t2.micro` (Free Tier).
6. **Key Pair**: Create a new key pair (`.pem`), download it, and keep it safe!
7. **Network Settings**:
   - Check **Allow SSH traffic**.
   - Check **Allow HTTP traffic from the internet**.
   - Check **Allow HTTPS traffic from the internet**.

### 2. Connect to your Server
Open your terminal (where your `.pem` file is) and run:
```bash
# Set permissions for your key (Linux/Mac only)
chmod 400 your-key.pem

# Connect to AWS
ssh -i "your-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
```

### 3. Install Docker on AWS
Once you are logged into the AWS terminal, run:
```bash
sudo apt-get update
sudo apt-get install docker.io docker-compose -y
sudo usermod -aG docker $USER
# Log out and log back in for permissions to take effect
exit
ssh -i "your-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
```

### 4. Deploy the Code
Since your `.env` and `firebase_cred.json` are NOT on GitHub, you need to upload them manually specifically to the server:
1. Clone your repo: `git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git`
2. Enter the folder: `cd YOUR_REPO_NAME`
3. **Manual Step**: Create your secret files on the server:
   ```bash
   nano .env  # Paste your .env content and press Ctrl+O, Enter, Ctrl+X
   nano server/firebase_cred.json  # Paste your JSON content and save
   ```
4. **Start the App**:
   ```bash
   docker-compose up --build -d
   ```

---

## 📱 Part 3: Connecting your Mobile App

1. Copy your **Public IPv4 Address** from the AWS Dashboard.
2. In VS Code, open `lib/core/services/api_config.dart`.
3. Update these lines:
```dart
static const bool useProduction = true; // Set to true!
static const String prodUrl = 'http://YOUR_AWS_PUBLIC_IP_HERE';
```
4. Build your app on your phone.

**Boom! Your app is now talking to the cloud!** 🚀✨
