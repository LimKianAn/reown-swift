import Foundation

public struct NotifyClientFactory {

    public static func create(projectId: String, groupIdentifier: String, networkInteractor: NetworkInteracting, pairingRegisterer: PairingRegisterer, pushClient: PushClient, crypto: CryptoProvider, notifyHost: String, explorerHost: String) -> NotifyClient {
        let logger = ConsoleLogger(prefix: "🔔",loggingLevel: .debug)
        let keyValueStorage = UserDefaults.standard
        let keyserverURL = URL(string: "https://keys.walletconnect.com")!
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")
        let groupKeychainService = GroupKeychainStorage(serviceIdentifier: groupIdentifier)

        return NotifyClientFactory.create(
            projectId: projectId,
            keyserverURL: keyserverURL,
            logger: logger,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            groupKeychainStorage: groupKeychainService,
            networkInteractor: networkInteractor,
            pairingRegisterer: pairingRegisterer,
            pushClient: pushClient,
            crypto: crypto,
            notifyHost: notifyHost,
            explorerHost: explorerHost
        )
    }

    static func create(
        projectId: String,
        keyserverURL: URL,
        logger: ConsoleLogging,
        keyValueStorage: KeyValueStorage,
        keychainStorage: KeychainStorageProtocol,
        groupKeychainStorage: KeychainStorageProtocol,
        networkInteractor: NetworkInteracting,
        pairingRegisterer: PairingRegisterer,
        pushClient: PushClient,
        crypto: CryptoProvider,
        notifyHost: String,
        explorerHost: String
    ) -> NotifyClient {
        let kms = KeyManagementService(keychain: keychainStorage)
        let subscriptionStore = KeyedDatabase<NotifySubscription>(storage: keyValueStorage, identifier: NotifyStorageIdntifiers.notifySubscription)
        let messagesStore = KeyedDatabase<NotifyMessageRecord>(storage: keyValueStorage, identifier: NotifyStorageIdntifiers.notifyMessagesRecords)
        let notifyAccountProvider = NotifyAccountProvider()
        let notifyStorage = NotifyStorage(subscriptionStore: subscriptionStore, messagesStore: messagesStore, accountProvider: notifyAccountProvider)
        let identityClient = IdentityClientFactory.create(keyserver: keyserverURL, keychain: keychainStorage, logger: logger)
        let notifyMessageSubscriber = NotifyMessageSubscriber(keyserver: keyserverURL, networkingInteractor: networkInteractor, identityClient: identityClient, notifyStorage: notifyStorage, crypto: crypto, logger: logger)
        let webDidResolver = NotifyWebDidResolver()
        let deleteNotifySubscriptionRequester = DeleteNotifySubscriptionRequester(keyserver: keyserverURL, networkingInteractor: networkInteractor, identityClient: identityClient, webDidResolver: webDidResolver, kms: kms, logger: logger, notifyStorage: notifyStorage)
        let resubscribeService = NotifyResubscribeService(networkInteractor: networkInteractor, notifyStorage: notifyStorage, logger: logger)

        let notifyConfigProvider = NotifyConfigProvider(projectId: projectId, explorerHost: explorerHost)

        let notifySubscribeRequester = NotifySubscribeRequester(keyserverURL: keyserverURL, networkingInteractor: networkInteractor, identityClient: identityClient, logger: logger, kms: kms, webDidResolver: webDidResolver, notifyConfigProvider: notifyConfigProvider)

        let notifySubscribeResponseSubscriber = NotifySubscribeResponseSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger, groupKeychainStorage: groupKeychainStorage, notifyStorage: notifyStorage, notifyConfigProvider: notifyConfigProvider)

        let notifyUpdateRequester = NotifyUpdateRequester(keyserverURL: keyserverURL, webDidResolver: webDidResolver, identityClient: identityClient, networkingInteractor: networkInteractor, notifyConfigProvider: notifyConfigProvider, logger: logger, notifyStorage: notifyStorage)

        let notifyUpdateResponseSubscriber = NotifyUpdateResponseSubscriber(networkingInteractor: networkInteractor, logger: logger, notifyConfigProvider: notifyConfigProvider, notifyStorage: notifyStorage)

        let subscriptionsAutoUpdater = SubscriptionsAutoUpdater(notifyUpdateRequester: notifyUpdateRequester, logger: logger, notifyStorage: notifyStorage)

        let notifyWatcherAgreementKeysProvider = NotifyWatcherAgreementKeysProvider(kms: kms)
        let notifyWatchSubscriptionsRequester = NotifyWatchSubscriptionsRequester(keyserverURL: keyserverURL, networkingInteractor: networkInteractor, identityClient: identityClient, logger: logger, webDidResolver: webDidResolver, notifyAccountProvider: notifyAccountProvider, notifyWatcherAgreementKeysProvider: notifyWatcherAgreementKeysProvider, notifyHost: notifyHost)
        let notifySubscriptionsBuilder = NotifySubscriptionsBuilder(notifyConfigProvider: notifyConfigProvider)
        let notifyWatchSubscriptionsResponseSubscriber = NotifyWatchSubscriptionsResponseSubscriber(networkingInteractor: networkInteractor, kms: kms, logger: logger, notifyStorage: notifyStorage, groupKeychainStorage: groupKeychainStorage, notifySubscriptionsBuilder: notifySubscriptionsBuilder)
        let notifySubscriptionsChangedRequestSubscriber = NotifySubscriptionsChangedRequestSubscriber(keyserver: keyserverURL, networkingInteractor: networkInteractor, kms: kms, identityClient: identityClient, logger: logger, groupKeychainStorage: groupKeychainStorage, notifyStorage: notifyStorage, notifySubscriptionsBuilder: notifySubscriptionsBuilder)
        let subscriptionWatcher = SubscriptionWatcher(notifyWatchSubscriptionsRequester: notifyWatchSubscriptionsRequester, logger: logger)

        let identityService = NotifyIdentityService(keyserverURL: keyserverURL, identityClient: identityClient, logger: logger)

        return NotifyClient(
            logger: logger,
            kms: kms,
            identityService: identityService,
            pushClient: pushClient,
            notifyMessageSubscriber: notifyMessageSubscriber,
            notifyStorage: notifyStorage,
            deleteNotifySubscriptionRequester: deleteNotifySubscriptionRequester,
            resubscribeService: resubscribeService,
            notifySubscribeRequester: notifySubscribeRequester,
            notifySubscribeResponseSubscriber: notifySubscribeResponseSubscriber,
            notifyUpdateRequester: notifyUpdateRequester,
            notifyUpdateResponseSubscriber: notifyUpdateResponseSubscriber,
            notifyAccountProvider: notifyAccountProvider,
            subscriptionsAutoUpdater: subscriptionsAutoUpdater,
            notifyWatchSubscriptionsResponseSubscriber: notifyWatchSubscriptionsResponseSubscriber, 
            notifyWatcherAgreementKeysProvider: notifyWatcherAgreementKeysProvider,
            notifySubscriptionsChangedRequestSubscriber: notifySubscriptionsChangedRequestSubscriber,
            subscriptionWatcher: subscriptionWatcher
        )
    }
}
