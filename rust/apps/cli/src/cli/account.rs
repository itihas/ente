use clap::{Args, Subcommand};

#[derive(Args)]
pub struct AccountCommand {
    #[command(subcommand)]
    pub command: AccountSubcommands,
}

#[derive(Subcommand)]
pub enum AccountSubcommands {
    /// List configured accounts
    List,

    /// Login into existing account
    #[command(alias = "login")]
    Add(AddArgs),

    /// Create a new account via email verification, key setup, and SRP registration
    #[command(alias = "signup")]
    Create(CreateArgs),

    /// Update an existing account's export directory
    Update {
        /// Email address of the account
        #[arg(long)]
        email: String,

        /// Export directory path
        #[arg(long)]
        dir: String,

        /// Specify the app (photos, locker, auth)
        #[arg(long, default_value = "photos")]
        app: String,
    },

    /// Get token for an account for a specific app
    GetToken {
        /// Email address of the account
        #[arg(long)]
        email: String,

        /// Specify the app (photos, locker, auth)
        #[arg(long, default_value = "photos")]
        app: String,
    },

    /// Enable TOTP two-factor for an existing account
    #[command(name = "two-factor", alias = "2fa")]
    TwoFactor {
        /// Email address of the account
        #[arg(long)]
        email: String,

        /// Specify the app (photos, locker, auth)
        #[arg(long, default_value = "photos")]
        app: String,

        /// TOTP code to use for enabling two-factor
        #[arg(long)]
        totp_code: Option<String>,

        /// Print the recovery key after enabling two-factor
        #[arg(long)]
        show_recovery_key: bool,
    },
}

#[derive(Args)]
pub struct AddArgs {
    /// Email address (optional - will prompt if not provided)
    #[arg(long)]
    pub email: Option<String>,

    /// Password (optional - will prompt if not provided)
    #[arg(long)]
    pub password: Option<String>,

    /// Specify the app (photos, locker, auth)
    #[arg(long, default_value = "photos")]
    pub app: String,

    /// API endpoint (defaults to https://api.ente.com)
    #[arg(long, default_value = "https://api.ente.com")]
    pub endpoint: String,

    /// Export directory path
    #[arg(long)]
    pub export_dir: Option<String>,

    /// Email verification code for email-MFA accounts
    #[arg(long)]
    pub otp: Option<String>,

    /// TOTP code to use if login requires two-factor verification
    #[arg(long)]
    pub totp_code: Option<String>,

    /// Preferred second-factor method when multiple are available (totp or passkey)
    #[arg(long)]
    pub second_factor: Option<String>,
}

#[derive(Args)]
pub struct CreateArgs {
    /// Email address (optional - will prompt if not provided)
    #[arg(long)]
    pub email: Option<String>,

    /// Password (optional - will prompt if not provided)
    #[arg(long)]
    pub password: Option<String>,

    /// Specify the app (photos, locker, auth)
    #[arg(long, default_value = "photos")]
    pub app: String,

    /// API endpoint (defaults to https://api.ente.com)
    #[arg(long, default_value = "https://api.ente.com")]
    pub endpoint: String,

    /// Export directory path
    #[arg(long)]
    pub export_dir: Option<String>,

    /// Signup email verification code
    #[arg(long)]
    pub otp: Option<String>,

    /// Referral/source string to pass during verify-email
    #[arg(long)]
    pub source: Option<String>,

    /// Enable TOTP two-factor immediately after signup
    #[arg(long)]
    pub setup_2fa: bool,

    /// TOTP code to use when enabling two-factor
    #[arg(long)]
    pub totp_code: Option<String>,

    /// Print the recovery key after signup
    #[arg(long)]
    pub show_recovery_key: bool,
}
