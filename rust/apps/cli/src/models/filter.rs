#[derive(Debug, Clone, Default)]
pub struct ExportFilter {
    pub include_shared: bool,

    pub include_hidden: bool,

    pub albums: Option<Vec<String>>,

    pub emails: Option<Vec<String>>,
}

impl ExportFilter {
    pub fn should_include_collection(
        &self,
        collection_name: &str,
        is_shared: bool,
        is_hidden: bool,
    ) -> bool {
        if is_shared && !self.include_shared {
            return false;
        }

        if is_hidden && !self.include_hidden {
            return false;
        }

        if let Some(ref albums) = self.albums
            && !albums.is_empty()
            && !albums.iter().any(|a| a == collection_name)
        {
            return false;
        }

        true
    }

    pub fn should_include_file_by_owner(&self, owner_email: Option<&str>) -> bool {
        if let Some(ref emails) = self.emails
            && !emails.is_empty()
        {
            if let Some(email) = owner_email {
                return emails.iter().any(|e| e == email);
            }
            return false;
        }
        true
    }
}
