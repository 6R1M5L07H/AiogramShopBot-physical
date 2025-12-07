<h1 align="center">AiogramShopBot</h1>

> **Note**: This is an enhanced fork of [ilyarolf/AiogramShopBot](https://github.com/ilyarolf/AiogramShopBot) with significant improvements including PGP encryption, tiered pricing, GDPR-compliant analytics, strike system, and advanced shipping management.

[![Python](https://img.shields.io/badge/Python_3.12-3776AB?logo=python&logoColor=%23fff)](https://www.python.org/downloads/release/python-3127/)
[![SQLite](https://img.shields.io/badge/SQLite-%2307405e.svg?logo=sqlite&logoColor=white)](https://www.sqlite.org/)
[![Bitcoin](https://img.shields.io/badge/Bitcoin-FF9900?logo=bitcoin&logoColor=white)](https://github.com/bitcoin/bitcoin)
[![Litecoin](https://img.shields.io/badge/Litecoin-A6A9AA?logo=litecoin&logoColor=white)](https://github.com/litecoin-project/litecoin)
[![Solana](https://img.shields.io/badge/Solana-9945FF?logo=solana&logoColor=fff)](https://github.com/solana-labs/solana)
[![Ethereum](https://img.shields.io/badge/Ethereum-3C3C3D?logo=ethereum&logoColor=white)](https://github.com/ethereum)
[![BinanceCoin](https://img.shields.io/badge/Binance-FCD535?logo=binance&logoColor=000)](https://github.com/binance)

**AiogramShopBot is a software product based on Aiogram3 and SQLAlchemy that allows you to automate sales of digital
goods in Telegram. One of the bot's advantages is that AiogramShopBot implements the ability to top up with Bitcoin,
Litecoin, Solana, Ethereum and Binance-Coin, which allows you to sell digital goods worldwide.**

* [🤝 Commercial offers](#commercial-offers)
    + [➤ Contact](#-for-commercial-offers-contact)
    + [🤖 Demo Bot](#-demo-bot-coming-soon)
* [1.Launch the bot](#1starting-the-bot)
    + [1.0 Description of required environment variables. ](#10-description-of-required-environment-variables)
    + [1.1 Launch AiogramShopBot with Docker-compose.](#11-starting-aiogramshopbot-with-docker-compose)
    + [1.2 Launch AiogramShopBot without SQLCipher database encryption.](#12-starting-aiogramshopbot-without-database-encryption)
    + [1.3 Launch AiogramShopBot with SQLCipher database encryption.](#13-starting-aiogramshopbot-with-sqlcipher-database-encryption)
* [2. 👥 AiogramShopBot User's Manual](#2aiogramshopbot-users-manual)
    + [2.1 🖥️ Registration](#21-registration)
    + [2.2 ➕ Top Up Balance](#22--top-up-balance)
    + [2.3 👜 Purchase of goods](#23-purchase-of-goods)
    + [2.4 🧾 Purchase History](#24--purchase-history)
* [3.   AiogramShopBot Admin Manual](#3aiogramshopbot-admin-manual)
    + [3.1   Adding a new admin](#31-adding-a-new-admin)
    + [3.2 📢 Announcements](#32--announcements)
        - [3.2.1 📢 Send to Everyone](#321--send-to-everyone)
        - [3.2.2   Restocking Message](#322--restocking-message)
        - [3.2.3 🗂️ Current Stock](#323--current-stock)
    + [3.3   Inventory Management](#33--inventory-management)
        - [3.3.1 ➕ Add Items](#331--add-items)
            - [3.3.1.1 JSON](#3311-json)
            - [3.3.1.2 TXT](#3312-txt)
    + [3.4 👥 User Management](#34--user-management)
        - [3.4.1 💳 Credit Management](#341--credit-management)
            - [3.4.1.1 ➕ Add balance](#3411--add-balance)
            - [3.4.1.2 ➖ Reduce balance](#3412--reduce-balance)
        - [3.4.2 ↩️ Make Refund](#342--make-refund)
    + [3.5   Analytics & Reports](#35--analytics--reports)
        - [3.5.1   Statistics](#351--statistics)
        - [3.5.2   Get database file](#352--get-database-file)
    + [3.6 🔔 Admin notifications](#36--admin-notifications)
        - [3.6.1 Notification to admin about new deposit](#361-notification-to-admin-about-new-deposit)
        - [3.6.2 Notification to admin about new buy](#362-notification-to-admin-about-new-buy)
    + [3.8 👛 Wallet](#38--wallet)
        - [3.8.1 Cryptocurrency withdrawal](#381-cryptocurrency-withdrawal-functionality)
* [4.0 Multibot (Experimental functionality)](#40-multibot-experimental-functionality)
    + [4.1 Starting the multibot](#41-starting-the-multibot)
* [  Todo List](#-todo-list)
* [MIT License](LICENSE)

## 📌Commercial offers

### ➤ For commercial offers contact: [YOUR_CONTACT]

### 🤖 Demo Bot: Coming soon

## 1.Starting the bot

### 1.0 Description of required environment variables

#### Environment-Specific Configuration Templates

For easier setup, use the appropriate template for your environment:

**Development (Local Testing):**
```bash
cp .env.dev.template .env
```
Optimized for local development with:
- Ngrok tunnel for webhooks
- Relaxed rate limits (100 orders/hour)
- DEBUG logging with SQL queries
- Disabled database encryption (faster)
- Shorter timeouts for faster testing

**Production (Live Deployment):**
```bash
cp .env.prod.template .env
```
Optimized for production with:
- External IP/domain (no ngrok)
- Strict rate limits (5 orders/hour)
- INFO logging (clean logs, no SQL)
- Database encryption enabled
- Automated backups enabled
- All security features enabled

**Universal Template:**
```bash
cp .env.template .env
```
General-purpose template with detailed documentation for all settings.

After copying the appropriate template, fill in all empty values and customize as needed.

#### Environment Variables Reference

| Environment Variable Name | Description                                                                                                                                                                                                                                                                                                                 | Recommend Value                                                     |
|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------|
| WEBHOOK_PATH              | The path to the webhook where Telegram servers send requests for bot updates. It is not recommended to change it if only one bot will be deployed. In case several bots will be deployed on the same server, it will be necessary to change it, because there will be path collision (Does not apply to the multibot case). | "" (empty string)                                                   |
| WEBAPP_HOST               | Hostname for Telegram bot, it is not recommended to change in case you use docker-compose.                                                                                                                                                                                                                                  | For docker-compose="0.0.0.0".<br/>For local deployment="localhost". |
| WEBAPP_PORT               | Port for Telegram bot, if you plan to deploy several bots on the same server, you will need to assign a different port to each one (Not relevant to the multibot case).                                                                                                                                                     | No recommended value                                                |
| TOKEN                     | Token from your Telegram bot, you can get it for free in Telegram from the bot of all bots with the username @botfather.                                                                                                                                                                                                    | No recommended value                                                |
| ADMIN_ID_LIST             | List of Telegram id of all admins of your bot. This list is used to check for access to the admin menu.                                                                                                                                                                                                                     | No recommended value                                                |
| SUPPORT_LINK              | A link to the Telegram profile that will be sent by the bot to the user when the “Help” button is pressed.                                                                                                                                                                                                                  | https://t.me/YOUR_USERNAME                                    |
| DB_NAME                   | The name of the SQLite database file.                                                                                                                                                                                                                                                                                       | database.db                                                         |
| DB_ENCRYPTION             | Boolean variable that enables database encryption.                                                                                                                                                                                                                                                                          | "true" of "false"                                                   |
| DB_PASS                   | Needs only if DB_ENCRYPTION=='true'. The password that will be used to encrypt your SQLite database with SQLCipher.                                                                                                                                                                                                         | Any string less than 31 characters                                  |
| NGROK_TOKEN               | Token from your NGROK profile, it is needed for port forwarding to the Internet. The main advantage of using NGROK is that NGROK assigns the HTTPS certificate for free.                                                                                                                                                    | No recommended value                                                |
| PAGE_ENTRIES              | The number of entries per page. Serves as a variable for pagination.                                                                                                                                                                                                                                                        | 8                                                                   |
| BOT_LANGUAGE              | The name of the .json file with the l10n localization. At the moment only English localization is supplied out of the box, but you can make your own if you create a file in the l10n folder with the same keys as in l10n/en.json.                                                                                         | "en" or "de"                                                        |
| MULTIBOT                  | Experimental functionality, allows you to raise several bots in one process. And there will be one main bot, where you can create other bots with the command “/add $BOT_TOKEN”. Accepts string parameters “true” or “false”.                                                                                               | "false"                                                             |
| CURRENCY                  | Currency to be used in the bot.                                                                                                                                                                                                                                                                                             | "USD" or "EUR" or "JPY" or "CAD" or "GBP"                           |
| RUNTIME_ENVIRONMENT       | If set to "dev", the bot will be connected via an ngrok tunnel. "prod" will use [Caddy](https://hub.docker.com/r/lucaslorentz/caddy-docker-proxy) as reverse proxy together with your public hostname                                                                                                                       | "prod" or "dev"                                                     |   
| WEBHOOK_SECRET_TOKEN      | Required variable, used to protect requests coming from Telegram servers from spoofing.                                                                                                                                                                                                                                     | Any string you want                                                 |   
| KRYPTO_EXPRESS_API_KEY    | API KEY from KryptoExpress profile                                                                                                                                                                                                                                                                                          | No recommended value                                                |   
| KRYPTO_EXPRESS_API_URL    | API URL from KryptoExpress service                                                                                                                                                                                                                                                                                          | https://KryptoExpress.pro/api                                       |   
| KRYPTO_EXPRESS_API_SECRET | Required variable, used to protect requests coming from KryptoExpress servers from spoofing.                                                                                                                                                                                                                                | Any string you want                                                 |   
| REDIS_PASSWORD            | Required variable, needed to make the throttling mechanism work.                                                                                                                                                                                                                                                            | Any string you want                                                 |
| REDIS_HOST                | Required variable, needed to make the throttling mechanism work.                                                                                                                                                                                                                                                            | "redis" for docker-compose.yml                                      |
| BOT_DOMAIN                | Domain for Telegram Mini App (PGP encryption feature). HTTPS required. Supports auto-configuration: leave empty in development (auto-set from ngrok URL), set explicitly in production (your domain or external IP). See "BOT_DOMAIN Auto-Configuration" section below for details.                                          | Empty (dev) or "bot.yourdomain.com" (prod)                          |
| WEBHOOK_MODE              | Determines how the bot receives updates from Telegram. "webhook" requires public HTTPS endpoint (ports 80/88/443/8443), "polling" requires no public endpoint. See "Webhook Mode and Polling Mode" section below for details.                                                                                               | "webhook" (default) or "polling"                                    |
| POLLING_TIMEOUT           | Timeout in seconds for polling updates from Telegram (1-50). Only used when WEBHOOK_MODE=polling. Lower value = faster response but more API calls. See "Webhook Mode and Polling Mode" section below.                                                                                                                      | 10 (only relevant for polling mode)                                 |

#### BOT_DOMAIN Auto-Configuration

The `BOT_DOMAIN` variable is used for the PGP-encrypted shipping address feature (Telegram Mini App). The bot automatically configures this value at startup if left empty:

**Development (ngrok)**:
- Leave `BOT_DOMAIN` empty in `.env`
- Bot starts ngrok tunnel → receives URL (e.g., `https://abc123.ngrok.io`)
- Automatically sets `BOT_DOMAIN` to ngrok URL
- Bot logs: `[Init] BOT_DOMAIN auto-configured from ngrok: https://abc123.ngrok.io`

**Production (external IP/domain)**:
- Option 1: Leave `BOT_DOMAIN` empty for auto-configuration with external IP
  - Bot calls sslipio → receives URL (e.g., `https://203.0.113.42.sslip.io`)
  - Automatically sets `BOT_DOMAIN` to external IP URL
  - Bot logs: `[Init] BOT_DOMAIN auto-configured from external IP: https://203.0.113.42.sslip.io`

- Option 2: Set `BOT_DOMAIN` explicitly to your custom domain
  - Example: `BOT_DOMAIN=bot.yourdomain.com` or `BOT_DOMAIN=https://bot.yourdomain.com`
  - Recommended for production deployments with fixed domains
  - Requires valid SSL certificate for the domain

Auto-configuration ensures the Mini App works immediately without manual URL configuration, while still allowing explicit configuration for production environments with custom domains.

#### Webhook Mode and Polling Mode

The bot supports two modes for receiving Telegram updates, configurable via the `WEBHOOK_MODE` environment variable:

**Webhook Mode (Default)**:
- Telegram pushes updates to your bot via HTTPS webhook
- Requires public HTTPS endpoint on ports: 80, 88, 443, or 8443
- Faster response time (instant delivery)
- Recommended for standard production deployments

**Polling Mode**:
- Bot polls Telegram API for updates via `getUpdates`
- No public endpoint required
- Slight delay in receiving updates (configurable, default ~1 second)
- Useful for environments where exposing public ports is not feasible

**Configuration:**

Set `WEBHOOK_MODE` in your `.env` file:
```bash
# Webhook mode (default, requires public HTTPS)
WEBHOOK_MODE=webhook

# Polling mode (no public endpoint needed)
WEBHOOK_MODE=polling

# Polling timeout in seconds (only used when WEBHOOK_MODE=polling)
# Lower value = faster response but more API calls. Default: 10
POLLING_TIMEOUT=10
```

**When to Use Each Mode:**

Use **Webhook Mode** when:
- You have a public server with HTTPS
- You can expose ports 80, 88, 443, or 8443
- You want instant update delivery

Use **Polling Mode** when:
- You cannot expose public webhook ports
- You don't have a public HTTPS endpoint
- You prefer simpler network setup without reverse proxy

Both modes support all bot features (background jobs, database operations, admin functions). The only difference is how updates are received from Telegram.

### 1.1 Starting AiogramShopBot with Docker-compose

#### First-Time Setup

Docker Compose files are stored as templates to prevent local customizations from being overwritten:

```bash
# Clone the project
git clone https://github.com/6R1M5L07H/AiogramShopBot-physical.git
cd AiogramShopBot-physical

# Copy the appropriate template for your environment:
# For production:
cp docker-compose.prod.yml.template docker-compose.prod.yml

# For development:
cp docker-compose.dev.yml.template docker-compose.dev.yml
```

> **Important**
> The `.template` files are version-controlled. Your local `docker-compose.prod.yml` and `docker-compose.dev.yml` files are ignored by git, so you can customize them without worrying about changes being overwritten during updates.

#### Production Deployment (Recommended)

For production deployment with Caddy reverse proxy and automatic TLS:

```bash
# Set up production environment (if not done already)
cp .env.prod.template .env
cp docker-compose.prod.yml.template docker-compose.prod.yml

# Edit .env and fill in all required values
# Edit docker-compose.prod.yml and set your domain (line 50)
# Replace YOUR-DOMAIN-GOES-HERE with:
#   - Your domain: bot.yourdomain.com
#   - Or sslip.io: 203.0.113.42.sslip.io (replace with your server IP)

# Start all services
docker-compose -f docker-compose.prod.yml up -d

# Check logs
docker-compose -f docker-compose.prod.yml logs -f bot

# Stop services
docker-compose -f docker-compose.prod.yml down
```

Features:
- Caddy reverse proxy with automatic HTTPS/TLS
- Redis with authentication
- Automated restarts
- Health checks
- Volume persistence for data and backups

#### Local Development - Redis only

For local development, run only Redis in Docker while running the bot directly on your machine:

```bash
# First-time setup
cp .env.dev.template .env
cp docker-compose.dev.yml.template docker-compose.dev.yml

# Start Redis
docker-compose -f docker-compose.dev.yml up -d

# Verify Redis is running
docker ps | grep redis

# Run the bot locally (in another terminal)
python run.py

# Stop Redis when done
docker-compose -f docker-compose.dev.yml down
```

> **Note**
> The `docker-compose.dev.yml` template is configured with a default Redis password: `dev-redis-password-123`.
> Update your `.env` file with: `REDIS_PASSWORD=dev-redis-password-123`

#### Development and production mode

For local development on a computer which is not internet facing, set the "RUNTIME_ENVIRONMENT" to "dev". The bot will
be connected via an ngrok tunnel.
> **Note**
> **<br>To get the ngrok token, you need to register on the ngrok website and confirm your email. Then you will have the
ngrok token in your personal account.<br>You will still need Redis.**

On an internet facing production system you can either set your own hostname in the caddy label (in the template shown
with "YOUR_DOMAIN_GOES_HERE"
or make use of services
like [sslip.io](https://sslip.io/). [Caddy](https://hub.docker.com/r/lucaslorentz/caddy-docker-proxy) will automatically
pull a TLS certificate
and serves as reverse proxy for your bot. You can also run your bot together with an already existing reverse proxy. In
this case you have to remove the caddy service from the docker-compose file and configure the reverse proxy accordingly.

### 1.2 Starting AiogramShopBot without database encryption.

* Clone the project from the master branch. <br>``git clone https://github.com/6R1M5L07H/AiogramShopBot-physical.git``
* Install all necessary packages <br>``pip install -r requirements.txt``
* Set the environment variables to run in the .env file.<br>Example:

```
WEBHOOK_PATH = "/"
WEBAPP_HOST = "localhost"
WEBAPP_PORT = 5000
TOKEN = "1234567890:QWER.....TYI"
ADMIN_ID_LIST = 123456,654321
SUPPORT_LINK = "https://t.me/YOUR_USERNAME"
DB_NAME = "database.db"
DB_ENCRYPTION = "false"
DB_PASS = ""
NGROK_TOKEN = "NGROK_TOKEN_HERE"
PAGE_ENTRIES = "8"
BOT_LANGUAGE = "en"
MULTIBOT = "false"
CURRENCY = "USD"
RUNTIME_ENVIRONMENT = "DEV"
WEBHOOK_SECRET_TOKEN = "1234567890"
KRYPTO_EXPRESS_API_KEY = "API_KEY_HERE"
KRYPTO_EXPRESS_API_URL = "https://kryptoexpress.pro/api"
KRYPTO_EXPRESS_API_SECRET = "1234567890"
REDIS_PASSWORD = "1234567890"
REDIS_HOST = "localhost"
```

* After these steps the bot is ready to run, launch the bot with command ```python run.py```

### 1.3 Starting AiogramShopBot with SQLCipher database encryption.

> **Note**
> **<br>To run AiogramShopBot with database encryption via SQLCipher, you need to use Linux kernel operating systems.**

* Clone the project.
  branch.<br>``git clone https://github.com/6R1M5L07H/AiogramShopBot-physical.git``
* Install the SQLCipher package, for example in Ubuntu this can be done with the
  command <br>``sudo apt install sqlcipher``.
* Install all necessary packages <br>``pip install -r requirements.txt``
* Install SQLCipher python package <br>``pip install sqlcipher3``
* Set the environment variables to run in the .env file.<br>Example:

```
WEBHOOK_PATH = "/"
WEBAPP_HOST = "localhost"
WEBAPP_PORT = 5000
TOKEN = "1234567890:QWER.....TYI"
ADMIN_ID_LIST = 123456,654321
SUPPORT_LINK = "https://t.me/YOUR_USERNAME"
DB_NAME = "database.db"
DB_ENCRYPTION = "true"
DB_PASS = "1234567890"
NGROK_TOKEN = "NGROK_TOKEN_HERE"
PAGE_ENTRIES = "8"
BOT_LANGUAGE = "en"
MULTIBOT = "false"
CURRENCY = "USD"
RUNTIME_ENVIRONMENT = "DEV"
WEBHOOK_SECRET_TOKEN = "1234567890"
KRYPTO_EXPRESS_API_KEY = "API_KEY_HERE"
KRYPTO_EXPRESS_API_URL = "https://kryptoexpress.pro/api"
KRYPTO_EXPRESS_API_SECRET = "1234567890"
REDIS_PASSWORD = "1234567890"
REDIS_HOST = "localhost"
```

* After these steps the bot is ready to run, the entry point to run the bot is run.py <br>```python run.py```

## 2.AiogramShopBot User's Manual

### 2.1 Registration

User registration occurs when the bot is first accessed with the ``/start`` command.

### 2.2 ➕ Top Up Balance

* Open my profile menu using the <u>“👤 My profile”</u> button.
* Open top-up menu using the <u>“➕ Top Up Balance”</u> button.
* In the resulting menu, click on cryptocurrency name button.
* Copy cryptocurrency address, and send cryptocurrency on this address.
* Once your transaction has at least one confirmation you will receive notification from the bot.

<br>![img](https://i.imgur.com/j2l7fHc.gif)

### 2.3 Purchase of goods

To buy any item, go to "All categories" -> Select any category -> Select any subcategory -> Select quantity -> Confirm
purchase. If the purchase is successful, you will immediately receive a message in the format:

![img](https://i.imgur.com/yEUw32h.gif)

### 2.4 🧾 Purchase History

* To access your purchase history go to "My Profile" -> "Purchase History".
* You will be presented with an inline keyboard with all your purchases, by clicking on any of the purchases you will be
  sent a message in the format from paragraph 2.3.

![imb](https://i.imgur.com/t5sA38N.gif)

## 3.AiogramShopBot Admin Manual

### 3.1 Adding a new admin

To add a new admin you need to add his telegram id to the ADMIN_ID_LIST environment variable, separated by commas, and
reload the bot.<br>For example: ``ADMIN_ID_LIST=123456,654321``

### 3.2 📢 Announcements

### 3.2.1 📢 Send to Everyone

* Open the admin menu using the <u>“  Admin Menu”</u> button.
* Open the announcements menu using the <u>“📢 Announcements”</u> button.
* In the resulting menu, click on <u>“📢 Send to Everyone”</u> button.
* Type a message or forward to the bot, the bot supports sending a message with pictures and Telegram markup (bold,
  italics, spoilers, etc.).
* Confirm or decline the sending of messages.
* After successful message sending, the original message with inline buttons "Confirm", "Decline" will change like on
  gif.<br>

![img](https://i.imgur.com/JYN6qx0.gif)

### 3.2.2   Restocking Message

* Open the admin menu using the <u>“  Admin Menu”</u> button.
* Open the announcements menu using the <u>“📢 Announcements”</u> button.
* In the resulting menu, click on <u>“  Restocking Message”</u> button.
* This message is generated based on items in the database that have "is_new" is true.

![img](https://i.imgur.com/lu3khwR.gif)

### 3.2.3 🗂️ Current Stock

* Open the admin menu using the <u>“  Admin Menu”</u> button.
* Open the announcements menu using the <u>“📢 Announcements”</u> button.
* In the resulting menu, click on <u>“🗂️ Current Stock”</u> button.
* This message is generated based on items in the database that have "is_sold" is false.

![img](https://i.imgur.com/T9wMPRG.gif)

### 3.3   Inventory Management

#### 3.3.1 ➕ Add Items

##### 3.3.1.1 JSON

* Open the admin menu using the <u>“  Admin Menu”</u> button.
* Open the announcements menu using the <u>“  Inventory Management”</u> button.
* Open the add items menu using the <u>“➕ Add Items”</u> button.
* In the resulting menu, click on <u>“JSON”</u> button.
* Send .json file with new items.<br>Example of .json file:

> **Note**
> The "private_data" property is what the user gets when they make a purchase.

```
[
  {
    "category": "Category#1",
    "subcategory": "Subcategory#1",
    "price": 50,
    "description": "Mocked description",
    "private_data": "Mocked private data"
  },
  {
    "category": "Category#2",
    "subcategory": "Subcategory#2",
    "price": 100,
    "description": "Mocked description",
    "private_data": "Mocked private data"
  }
]
```

![img](https://i.imgur.com/zjS4v8k.gif)

##### 3.3.1.2 TXT

* Open the admin menu using the <u>“  Admin Menu”</u> button.
* Open the inventory management menu using the <u>“  Inventory Management”</u> button.
* Open the add items menu using the <u>“➕ Add Items”</u> button.
* In the resulting menu, click on <u>“TXT”</u> button.
* Send .txt file with new items.<br>Example of .txt file:

```
CATEGORY#1;SUBCATEGORY#1;DESCRIPTION#1;50.0;PRIVATE_DATA#1
CATEGORY#1;SUBCATEGORY#1;DESCRIPTION#1;50.0;PRIVATE_DATA#2
CATEGORY#1;SUBCATEGORY#1;DESCRIPTION#1;50.0;PRIVATE_DATA#3
CATEGORY#1;SUBCATEGORY#1;DESCRIPTION#1;50.0;PRIVATE_DATA#4
CATEGORY#1;SUBCATEGORY#1;DESCRIPTION#1;50.0;PRIVATE_DATA#5
CATEGORY#1;SUBCATEGORY#1;DESCRIPTION#1;50.0;PRIVATE_DATA#6
CATEGORY#1;SUBCATEGORY#1;DESCRIPTION#1;50.0;PRIVATE_DATA#7
CATEGORY#1;SUBCATEGORY#1;DESCRIPTION#1;50.0;PRIVATE_DATA#8
```

![img](https://i.imgur.com/jct3qGc.gif)

#### 3.3.2 🗑️ Delete Category/Subcategory

> Note: This way, you will delete all products from “All categories” with the category or subcategory you picked and
> deleted.

* Open the admin menu using the <u>“  Admin Menu”</u> button.
* Open the inventory management menu using the <u>“  Inventory Management”</u> button.
* Open the add items menu using the <u>“🗑️ Delete Category”</u> or <u>“🗑️ Delete Subcategory”</u> button.
* In the resulting menu, select the category or subcategory you want to delete.
* Confirm or cancel the deletion of the category or subcategory.

![img](https://i.imgur.com/foFKU0y.gif)

### 3.4 👥 User Management

#### 3.4.1 💳 Credit Management

##### 3.4.1.1 ➕ Add balance

* Open the admin menu using the <u>“  Admin Menu”</u> button.
* Open the user management menu using the <u>“👥 User Management”</u> button.
* Open the credit management menu using the <u>“💳 Credit Management”</u> button.
* In the resulting menu, click on <u>“➕ Add balance”</u> button.
* Send the user entity object that belongs to the user you want to add the balance to. This can be telegram id or
  telegram username.
* Send the value by which you want to add the balance to the user.

![img](https://i.imgur.com/6HXd460.gif)

##### 3.4.1.2 ➖ Reduce balance

* Open the admin menu using the <u>“  Admin Menu”</u> button.
* Open the user management menu using the <u>“👥 User Management”</u> button.
* Open the credit management menu using the <u>“💳 Credit Management”</u> button.
* In the resulting menu, click on <u>“➖ Reduce balance”</u> button.
* Send the user entity object that belongs to the user you want to add the balance to. This can be telegram id or
  telegram username.
* Send the value by which you want to reduce the balance to the user.

![img](https://i.imgur.com/4JPbWZd.gif)

#### 3.4.2 ↩️ Make Refund

* Open the admin menu using the <u>“  Admin Menu”</u> button.
* Open the user management menu using the <u>“👥 User Management”</u> button.
* Open the refund menu using the <u>“↩️ Make Refund”</u> button.
* In the resulting menu, click on the buy button you want to refund.
* Confirm or cancel refund.

![img](https://i.imgur.com/hZ7UvJJ.gif)

### 3.5   Analytics & Reports

### 3.5.1   Statistics

* Open the admin menu using the <u>“  Admin Menu”</u> button.
* Open the statistics menu using the <u>“  Analytics & Reports”</u> button.
* In the resulting menu, click on the entity for which you want to get statistics.
* In the resulting menu, click on the time period for which you want statistics.

![img](https://i.imgur.com/lmuo0QY.gif)

### 3.5.2   Get database file

* Open the admin menu using the <u>“  Admin Menu”</u> button.
* Open the statistics menu using the <u>“  Analytics & Reports”</u> button.
* Click <u>"  Get database file"</u> button.

![img](https://i.imgur.com/hKTGFu6.gif)

### 3.6 🔔 Admin notifications

> **Note**
> All users with telegram id in the .env ADMIN_ID_LIST environment variable will receive these notifications

#### 3.6.1 Notification to admin about new deposit

* If any user topped up the balance and clicked on the "Refresh balance" button, you will receive the following message
  from the bot:

![img](https://i.imgur.com/FSXzEoW.gif)

#### 3.6.2 Notification to admin about new buy

After each purchase, you will receive a message in the format:

![img](https://i.imgur.com/MeRkCYD.gif)

### 3.8 👛 Wallet

#### 3.8.1 Cryptocurrency withdrawal functionality

To withdraw cryptocurrency from the bot, open the admin menu, go to the wallet tab, select the cryptocurrency you want to withdraw, send the cryptocurrency address where you want to withdraw and confirm the withdrawal. After a successful withdrawal, the bot will send you a link to the blockchain browser with the transaction.

![img](https://i.imgur.com/gjkRFVb.gif)

## 4.0 Multibot (Experimental functionality)

### 4.1 Starting the multibot

* Set all environment variables in docker-compose.yml and set the variable “true” for MULTIBOT.
  ``MULTIBOT="true"``
* Run the ``docker-compose up`` command.
* After successful execution of the command, you will only deploy a manager bot for other bots, it will not have
  functionality for buying items etc. To deploy a bot with functionality to sell goods etc..., you need to send the
  command ``/add $TOKEN`` to the bot manager. If everything is successful, you will receive this notification.

![img](https://i.imgur.com/YAGjN3G.png)

##   Todo List

- [x] Make migration from direct raw database queries to SQLAlchemy ORM.
- [x] Add option to encrypt database via SQLCipher (when using SQLAlchemy).
- [x] Add an option to generate new crypto addresses using new mnemonic phrases so that 1 user=1 mnemonic phrase.
- [x] Items pagination.
- [x] Make the functionality of database backup by action in the admin in the Telegram bot.
- [x] Make the functionality of generating statistics of sales and users in the bot for a month/week/day in the admin
  panel.
- [x] Make the functionality of generating statistics of deposits in the bot for a month/week in the admin
  panel.

