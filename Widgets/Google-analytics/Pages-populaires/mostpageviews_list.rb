require 'google/api_client'
require 'date'
 
# Update these to match your own apps credentials
service_account_email = '[YOUR SERVICE ACCOUNT EMAIL]' # Email of service account
key_file = 'path/to/your/keyfile.p12' # File containing your private key
key_secret = 'notasecret' # Password to unlock private key
profileID = '[YOUR PROFILE ID]' # Analytics profile ID.
 
# Get the Google API client
client = Google::APIClient.new(:application_name => '[YOUR APPLICATION NAME]', 
  :application_version => '0.01')
 
# Load your credentials for the service account
key = Google::APIClient::KeyUtils.load_from_pkcs12(key_file, key_secret)
client.authorization = Signet::OAuth2::Client.new(
  :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
  :audience => 'https://accounts.google.com/o/oauth2/token',
  :scope => 'https://www.googleapis.com/auth/analytics.readonly',
  :issuer => service_account_email,
  :signing_key => key)
 
# Start the scheduler
SCHEDULER.every '30m', :first_in => 0 do
 
  # Request a token for our service account
  client.authorization.fetch_access_token!
 
  # Get the analytics API
  analytics = client.discovered_api('analytics','v3')
 
  # Start and end dates
  startDate = DateTime.now.strftime("%Y-%m-01") # first day of current month
  endDate = DateTime.now.strftime("%Y-%m-%d")  # now
 
 # Déclaration des array
  urlpage = Array.new
  nbrvues = Array.new
  results = Array.new
  
  # Execute the query
  mostpageviews_List = client.execute(:api_method => analytics.data.ga.get, :parameters => { 
    'ids' => "ga:" + profileID, 
    'start-date' => startDate,
    'end-date' => endDate,
    'dimensions'=> "ga:pagePath",
    'metrics'=> "ga:pageviews",
    'max-results' => 5,
    'sort'=> "-ga:pageviews",
  })
 
 # Récupération des urls et du nombre de vues séparées
 urlpage = mostpageviews_List.data.rows.transpose[0]
 nbrvues = mostpageviews_List.data.rows.transpose[1]
 
 # Affectation des données
 compteur= 0
 urlpage.each do |row|
 results.push({label: urlpage[compteur], value: nbrvues[compteur]})
 compteur += 1
 end
 
 
  # Update the dashboard
  send_event('mostpageviews_list',   { items: results })
end
