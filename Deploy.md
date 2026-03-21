# Week 5: Deploy Your Capstone to DigitalOcean App Platform 🚀

**Time Estimate**: 2-3 hours  
**Goal**: Deploy your Rails capstone to DigitalOcean with file uploads and a managed database

Congratulations! You've built an amazing Rails application. Now it's time to share it with the world by deploying it to DigitalOcean's App Platform. This tutorial will guide you through setting up object storage for file uploads, a managed PostgreSQL database, and deploying your app to the cloud.

---

## Prerequisites

### Accept Your DigitalOcean Team Invitation

Before you begin, you should have received an email invitation to join the course DigitalOcean team. **You must accept this invitation first** to access the shared account where your app will be deployed.

1. Check your email for an invitation from DigitalOcean
2. Click the link and accept the invitation
3. Log in to the DigitalOcean dashboard at [cloud.digitalocean.com](https://cloud.digitalocean.com)

---

## Step 1: Configure Active Storage for DigitalOcean Spaces

DigitalOcean Spaces is an S3-compatible object storage service that will store your uploaded files (images, documents, etc.). We need to configure Rails to use Spaces instead of local disk storage.

### Add the AWS S3 SDK Gem

First, add the AWS SDK gem to your Gemfile. Even though we're using DigitalOcean Spaces, it uses the same protocol as Amazon S3, so we use the AWS SDK.

**In your `Gemfile`**, add:

```ruby
# For DigitalOcean Spaces (S3-compatible storage)
gem "aws-sdk-s3", require: false
```

Then run:

```bash
bundle install
```

### Configure Storage Settings

**In `config/storage.yml`**, add the following configuration:

```yaml
digital_ocean:
  service: S3
  endpoint: <%= ENV.fetch("S3_ENDPOINT", "") %>
  access_key_id: <%= ENV.fetch("S3_ACCESS_KEY_ID", "") %>
  secret_access_key: <%= ENV.fetch("S3_SECRET_ACCESS_KEY", "") %>
  bucket: <%= ENV.fetch("S3_BUCKET", "") %>
  region: unused
```

**Note**: The `region` is set to `unused` because DigitalOcean Spaces handles regions differently than AWS S3.

### Update Production Configuration

**In `config/environments/production.rb`**, find the line that configures Active Storage and update it:

```ruby
# Store uploaded files on DigitalOcean Spaces
config.active_storage.service = :digital_ocean
```

Look for a line that says something like:
```ruby
config.active_storage.service = :local
```

Replace it with:
```ruby
config.active_storage.service = :digital_ocean
```

### Commit and Push Your Changes

⚠️ **IMPORTANT**: You must commit these changes before deploying! The deployment will fail without these configurations.

```bash
git add .
git commit -m "Configure Active Storage for DigitalOcean Spaces deployment"
git push origin main
```

---

## Step 2: Set Up Your PostgreSQL Database

DigitalOcean's Managed Databases provide a reliable, scalable PostgreSQL database that your app will use in production. I've already created a PostgreSQL database cluster in our team account - you just need to create a database for your specific app.

### Create Your Database

📹 **[Watch the screen recording showing how to create a database]**



https://github.com/user-attachments/assets/6e96cb39-08ef-47df-8574-22222b6f7451



Follow these steps:

1. Go to the [DigitalOcean Dashboard](https://cloud.digitalocean.com)
2. Click on **Databases** in the left sidebar
3. Find the shared PostgreSQL cluster (it should be visible in the team account)
4. Click on the cluster name
5. Go to the **Users & Databases** tab
6. Click **Add New Database**
7. **Name your database**: Use your **first name** + app name (e.g., `jane_island_formulator` or `john_my_app`)
   - ⚠️ **Use your first name to ensure uniqueness** - multiple students are using this team account!
8. Click **Save**

### Get Your Connection String

Once your database is created:

1. In the database cluster page, look for **Connection Details**
2. Find the **Connection String** - it will look like:
   ```
   postgres://username:password@db-postgresql-nyc1-XXXXX-do-user-XXXXX-0.db.ondigitalocean.com:25060/database_name?sslmode=require
   ```
3. **Copy this connection string** - you'll need it when configuring your app
4. Keep this string safe - it contains your database password!

---

## Step 3: Create Your Spaces Bucket and Access Keys

Now we need to create a bucket in DigitalOcean Spaces to store your uploaded files, plus access keys that your app will use to connect to the bucket.

### Create a Spaces Bucket

📹 **[Watch the screen recording showing how to create a Spaces bucket and access keys]**

https://github.com/user-attachments/assets/fa0d0c62-f464-49ab-b155-e58e0e41fa31

Follow these steps:

1. In the DigitalOcean Dashboard, click on **Spaces** in the left sidebar
2. Click **Create a Space**
3. **Choose a datacenter region**: Select **NYC3** (New York City 3) - this is important!
4. **Choose a unique name**: Use your **first name** + app name + bucket (e.g., `jane-island-formulator-bucket` or `john-recipe-app-bucket`)
   - ⚠️ **Must be globally unique and include your first name** - bucket names are shared across all DigitalOcean users!
5. **CDN**: Leave this unchecked (disabled) for now
6. Click **Create a Space**

### Create Access Keys

⚠️ **IMPORTANT**: Pay close attention to this step! Secret keys are shown only once and cannot be recovered.

1. In the DigitalOcean Dashboard, go to **API** in the left sidebar
2. Click on **Spaces Keys**
3. Click **Generate New Key**
4. Give your key a name (e.g., `jane-island-formulator-app` - include your first name)
5. Click the checkmark to create the key
6. **CRITICAL**: You will see two values:
   - **Key**: This is your access key (starts with something like `DO00...`)
   - **Secret**: This is your secret key - **COPY THIS NOW!**

⚠️ **Store the secret key somewhere safe immediately** - once you close this dialog or navigate away, the secret key cannot be retrieved again. If you lose it, you'll need to generate a new key pair.

### Gather Your Spaces Information

You'll need these values for the next steps:

- **S3_ENDPOINT**: `https://nyc3.digitaloceanspaces.com`
- **S3_ACCESS_KEY_ID**: The Key you just created
- **S3_SECRET_ACCESS_KEY**: The Secret you just saved
- **S3_BUCKET**: The name of your bucket

---

## Step 4: Deploy to DigitalOcean App Platform

Now for the exciting part - deploying your app!

📹 **[Watch the screen recording showing how to create an app in App Platform]**



https://github.com/user-attachments/assets/6db860e2-7a70-4802-9110-345f8b9f604c




### Create Your App

1. Go to the DigitalOcean Dashboard
2. Click **Apps** in the left sidebar
3. Click **Create App**
4. Select **GitHub** as the source
5. Choose your repository from the list
6. Click **Next**

### Configure Your App

1. **Name your app**: Use your first name + app name (e.g., `jane-island-formulator`)
   - ⚠️ **Include your first name for uniqueness** - this determines your URL!
2. **Region**: Select **NYC1** (New York) - this is important!
3. **Branch**: Select `main` (or your default branch)
4. **Source Directory**: Leave as `/` (root)

### Select Your Plan

- For this course, use the **Basic** plan
- Select the **$5/month** instance size
- This is perfect for capstone projects and provides enough resources

### Configure Environment Variables

Before you create the app, you need to set several environment variables. Click **Edit** next to **Environment Variables** and add these:

#### Required Variables

**1. DATABASE_URL**
- **Key**: `DATABASE_URL`
- **Value**: Paste the connection string from Step 2
- **Encrypt**: ✅ Yes (check the box)

**2. SECRET_KEY_BASE**
This is a secret key used by Rails for encryption and security.

To generate it, run this command in your terminal:
```bash
rails secret
```

This will output a long string of random characters. Copy that and:
- **Key**: `SECRET_KEY_BASE`
- **Value**: Paste the generated secret
- **Encrypt**: ✅ Yes

**3. S3_ENDPOINT**
- **Key**: `S3_ENDPOINT`
- **Value**: `https://nyc3.digitaloceanspaces.com`
- **Encrypt**: ✅ Yes

**4. S3_ACCESS_KEY_ID**
- **Key**: `S3_ACCESS_KEY_ID`
- **Value**: Your Spaces access key (from Step 3)
- **Encrypt**: ✅ Yes

**5. S3_SECRET_ACCESS_KEY**
- **Key**: `S3_SECRET_ACCESS_KEY`
- **Value**: Your Spaces secret key (from Step 3)
- **Encrypt**: ✅ Yes

**6. S3_BUCKET**
- **Key**: `S3_BUCKET`
- **Value**: Your bucket name (from Step 3)
- **Encrypt**: ✅ Yes

### Review and Create

1. Review all your settings
2. Make sure the region is **NYC3**
3. Make sure you've added all 6 environment variables
4. Click **Create Resources**

---

## Step 5: Watch the Deployment

DigitalOcean will now build and deploy your app. This process takes about 5-10 minutes.

1. You'll be taken to the app dashboard
2. Click on **Activity** or **Build Logs** to watch the progress
3. You can see each step:
   - Cloning your repository
   - Installing Ruby gems
   - Precompiling assets
   - Running database migrations
   - Starting the server

### Common Build Steps

You'll see logs showing:
```
==> Building app
==> Using Ruby version 3.x.x
==> Installing gems
==> Preparing assets
==> Running build commands
==> Uploading build
```

If everything goes well, you'll see a **"Build successful"** message!

---

## Step 6: Set Up Your Database

After the initial deployment, you need to run database migrations to create your tables.

### Access the Console

1. In your App Platform dashboard, click on the **Console** tab
2. This opens a terminal connected to your running app

### Run Migrations

In the console, run:

```bash
rails db:migrate
```

Wait for this to complete. You should see output showing each migration being applied.

### (Optional) Seed Your Database

If you have seed data in `db/seeds.rb`:

```bash
rails db:seed
```

---

## Step 7: Test Your Live App

Once deployment is complete:

1. Go to the **Overview** tab in your App Platform dashboard
2. Copy the URL shown at the top (something like `https://jane-island-formulator-xyz.ondigitalocean.app`)
3. Open it in your browser

### Testing Checklist

Test these features to make sure everything is working:

- [ ] **Homepage loads** - No errors on the main page
- [ ] **Sign up** - Create a new user account
- [ ] **Log in** - Sign in with your new account
- [ ] **Create records** - Add ingredients, recipes, etc.
- [ ] **File uploads work** - Upload a photo (this tests Spaces integration)
- [ ] **View uploaded files** - Make sure images display correctly
- [ ] **All CRUD operations** - Create, read, update, delete work for all resources

---

## Troubleshooting

### "Missing host to link to!" Error

If you see this error, Rails doesn't know your app's URL.

**Fix**: In `config/environments/production.rb`, add or update:

```ruby
config.action_mailer.default_url_options = { host: 'your-app-name.ondigitalocean.app' }
```

Replace with your actual app URL.

### Database Connection Errors

If your app can't connect to the database:

1. Double-check your `DATABASE_URL` environment variable
2. Make sure the database exists (you created it in Step 2)
3. Verify the connection string is complete and correct
4. Check that the database cluster is in the same region as your app (NYC3)

### File Upload Errors

If uploads aren't working:

1. Check all S3-related environment variables are set correctly
2. Verify your Spaces bucket exists and is in NYC3
3. Make sure your access keys are correct
4. Check that `config.active_storage.service = :digital_ocean` is set in production.rb

### Assets Not Loading (CSS/JS)

If your app looks unstyled:

1. Check the build logs for errors during asset compilation
2. Make sure you have this in your build process (App Platform usually handles this automatically)
3. Try redeploying

### "Application Error" on First Load

If you see a generic error page:

1. Check the **Runtime Logs** in your App Platform dashboard
2. Look for specific error messages
3. Common causes: missing environment variables, database not migrated, or syntax errors

---

## Understanding Your Deployment

### What You Built

You now have a production-ready application with:

- **Web Application**: Running on DigitalOcean App Platform
- **Database**: PostgreSQL on DigitalOcean Managed Databases
- **File Storage**: DigitalOcean Spaces (S3-compatible object storage)
- **Automatic Deployments**: Push to GitHub → Auto-deploy to DigitalOcean

### Environment Variables Explained

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | Connection string to your PostgreSQL database |
| `SECRET_KEY_BASE` | Rails encryption key for sessions and cookies |
| `S3_ENDPOINT` | URL for DigitalOcean Spaces (region-specific) |
| `S3_ACCESS_KEY_ID` | Your Spaces access credential |
| `S3_SECRET_ACCESS_KEY` | Your Spaces secret credential |
| `S3_BUCKET` | Name of your Spaces bucket |

### Why Use Your First Name?

Since all students are deploying to a shared DigitalOcean team account, **using your first name** ensures:
- **Unique database names**: No conflicts with other students' databases
- **Unique bucket names**: Globally unique across all DigitalOcean users
- **Unique app names**: Your URL won't conflict with classmates
- **Easy identification**: Instructors can quickly identify which resources belong to whom

**Examples:**
- Jane's database: `jane_island_formulator`
- Jane's bucket: `jane-island-formulator-bucket`
- Jane's app: `jane-island-formulator`

---

## Maintenance and Updates

### Updating Your App

When you make changes:

1. Commit your changes locally:
   ```bash
   git add .
   git commit -m "Your changes"
   ```

2. Push to GitHub:
   ```bash
   git push origin main
   ```

3. DigitalOcean will automatically detect the push and redeploy your app!

### Viewing Logs

To see what's happening in your app:

1. Go to your App Platform dashboard
2. Click on **Runtime Logs**
3. You'll see real-time logs from your application

---

## Congratulations! 🎉

Your capstone project is now live on the internet! You can:

- Share your URL with friends and family
- Add it to your portfolio and resume
- Continue improving it - changes automatically deploy when you push to GitHub

**You did it! Your Rails application is deployed and ready for the world!** 🚀✨

---

## Quick Reference Checklist

Before you start:
- [ ] Accepted DigitalOcean team invitation
- [ ] Added `aws-sdk-s3` gem
- [ ] Updated `config/storage.yml`
- [ ] Updated `config/environments/production.rb`
- [ ] **Committed and pushed all changes**

Database setup:
- [ ] Created database with your first name (e.g., `jane_island_formulator`)
- [ ] Copied connection string

Spaces setup:
- [ ] Created bucket in NYC3 with your first name (e.g., `jane-island-formulator-bucket`)
- [ ] Generated access keys
- [ ] **Saved the secret key somewhere safe**

Deployment:
- [ ] Created app in NYC3 with your first name (e.g., `jane-island-formulator`)
- [ ] Set all 6 environment variables (including `https://nyc3.digitaloceanspaces.com` as endpoint)
- [ ] Ran database migrations
- [ ] Tested the live app
