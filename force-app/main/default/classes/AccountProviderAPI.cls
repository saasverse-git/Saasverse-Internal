@RestResource(urlMapping='/getAccountDetails')
global class AccountProviderAPI {
    @httpGet
    global static List<Account> getAllAccounts(){
        return [select Id, Name from Account LIMIT 5];
    }
}