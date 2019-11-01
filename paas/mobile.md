# Create Azure App Service Mobile Apps

## Objectives
* Coding pattern for implementing offline sync in the mobile client.

## What is Azure Mobile Apps?
Azure Mobile Apps are a specific type of Azure App Service to support mobile applications, and bring along all of the features of App Services.

Instead of running a web application, they provide a REST based API to backend data.

Mobile device SDK's are provided for Windows, iOS, Android, Xamarin, and Cordova. The SDK provices secure connectivity, push notifications, data access, offline data storage, and data syncronization.

## Create an App Service Mobile App Service
```csharp
#define OFFLINE_SYNC_ENABLED

using System;
using System.Net.Http;
using System.Threading.Tasks;
using System.Collections.Generic;
using Microsoft.WindowsAzure.MobileServices;

#if OFFLINE_SYNC_ENABLED
using Microsoft.WindowsAzure.MobileServices.SQLiteStore;
using Microsoft.WindowsAzure.MobileServices.Sync;
#endif

using UIKit;

namespace az203
{
    public class QSTodoService
    {
        private MobileServiceUser user;
        public MobileServiceUser User { get { return user; } }

        static QSTodoService instance = new QSTodoService ();

        const string applicationURL = @"https://az203.azurewebsites.net";

        private MobileServiceClient client;
#if OFFLINE_SYNC_ENABLED
        const string localDbPath = "localstore.db";

        private IMobileServiceSyncTable<ToDoItem> todoTable;
#else
        private IMobileServiceTable<ToDoItem> todoTable;
#endif

        private QSTodoService ()
        {
            CurrentPlatform.Init();

            client = new MobileServiceClient(applicationURL);

#if OFFLINE_SYNC_ENABLED

			// Initialize the store
			InitializeStoreAsync().ContinueWith(_ =>
			{
				// Create an MSTable instance to allow us to work with the TodoItem table
				todoTable = client.GetSyncTable<ToDoItem>();
			});
#else
            todoTable = client.GetTable<ToDoItem>();
#endif
        }

        public static QSTodoService DefaultService {
            get {
                return instance;
            }
        }
        
        public async Task Authenticate(UIViewController view)
        {
            try
            {
                AppDelegate.ResumeWithURL = url => url.Scheme == "az293" && client.ResumeWithURL(url);
                user = await client.LoginAsync(view, MobileServiceAuthenticationProvider.Google, "az293");
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine(@"ERROR - AUTHENTICATION FAILED {0}", ex.Message);
            }
        }
        
        public List<ToDoItem> Items { get; private set;}

        public async Task InitializeStoreAsync()
        {
#if OFFLINE_SYNC_ENABLED
			try
            {
                var store = new MobileServiceSQLiteStore("localstore.db");
                store.DefineTable<ToDoItem>();

				// Uses the default conflict handler, which fails on conflict
				// To use a different conflict handler, pass a parameter to InitializeAsync.
				// For more details, see http://go.microsoft.com/fwlink/?LinkId=521416
                await client.SyncContext.InitializeAsync(store);
                
                store = null;
			} 
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }
#endif
        }

        public async Task SyncAsync(bool pullData = false)
        {
#if OFFLINE_SYNC_ENABLED
            try
            {
                await client.SyncContext.PushAsync();

                if (pullData) 
                {
                    await todoTable.PullAsync("allTodoItems", todoTable.CreateQuery()); // query ID is used for incremental sync
                }
            }
            catch (MobileServiceInvalidOperationException e)
            {
                Console.Error.WriteLine(@"Sync Failed: {0}", e.Message);
            }
#endif
        }

        public async Task<List<ToDoItem>> RefreshDataAsync ()
        {
            try 
            {
#if OFFLINE_SYNC_ENABLED
                // Update the local store
                await SyncAsync(pullData: true);
#endif

                // This code refreshes the entries in the list view by querying the local TodoItems table.
                // The query excludes completed TodoItems
                Items = await todoTable.Where (todoItem => todoItem.Complete == false).ToListAsync ();
            } 
            catch (MobileServiceInvalidOperationException e) 
            {
                Console.Error.WriteLine (@"ERROR {0}", e.Message);
                return null;
            }

            return Items;
        }

        public async Task InsertTodoItemAsync (ToDoItem todoItem)
        {
            try 
            {
                await todoTable.InsertAsync (todoItem); // Insert a new TodoItem into the local database.
#if OFFLINE_SYNC_ENABLED
                await SyncAsync(); // Send changes to the mobile app backend.
#endif
                Items.Add (todoItem);
            } 
            catch (MobileServiceInvalidOperationException e) 
            {
                Console.Error.WriteLine (@"ERROR {0}", e.Message);
            }
        }

        public async Task CompleteItemAsync (ToDoItem item)
        {
            try 
            {
                item.Complete = true;
                await todoTable.UpdateAsync (item); // Update todo item in the local database
#if OFFLINE_SYNC_ENABLED
                await SyncAsync(); // Send changes to the mobile app backend.
#endif
                Items.Remove (item);
            } 
            catch (MobileServiceInvalidOperationException e) 
            {
                Console.Error.WriteLine (@"ERROR {0}", e.Message);
            }
        }
    }
}
```

## References
* [About Mobile Apps in Azure App Service](https://docs.microsoft.com/en-us/azure/app-service-mobile/app-service-mobile-value-prop).
* [Create a Windows app with an Azure backend](https://docs.microsoft.com/en-us/azure/app-service-mobile/app-service-mobile-windows-store-dotnet-get-started).
* [Enable offline sync for your Windows app](https://docs.microsoft.com/en-us/azure/app-service-mobile/app-service-mobile-windows-store-dotnet-get-started-offline-data).
