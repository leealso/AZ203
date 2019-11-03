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

        static QSTodoService instance = new QSTodoService();

        const string applicationURL = @"https://az203.azurewebsites.net";

        // Provides basic access to a Microsoft Azure Mobile Service
        private MobileServiceClient client;
#if OFFLINE_SYNC_ENABLED
        const string localDbPath = "localstore.db";

        // Provides operations on local table
        private IMobileServiceSyncTable<ToDoItem> todoTable;
#else
        // Provides operations on a table for a Microsoft Azure Mobile Service
        private IMobileServiceTable<ToDoItem> todoTable;
#endif

        private QSTodoService()
        {
            CurrentPlatform.Init();

            client = new MobileServiceClient(applicationURL);

#if OFFLINE_SYNC_ENABLED
            InitializeStoreAsync().ContinueWith(_ =>
            {
                // Returns a IMobileServiceSyncTable<T> instance, which provides strongly typed data operations for local table
                todoTable = client.GetSyncTable<ToDoItem>();
            });
#else
            // Returns a IMobileServiceTable<T> instance, which provides strongly typed data operations for that table
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
                AppDelegate.ResumeWithURL = url => url.Scheme == "az203" && client.ResumeWithURL(url);
                user = await client.LoginAsync(view, MobileServiceAuthenticationProvider.Google, "az203");
            }
            catch(Exception ex)
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
                // A SQLite based implementation of MobileServiceStore
                var store = new MobileServiceSQLiteStore("localstore.db");
                // Defines schema of a table in the local store
                // If a table with the same name already exists, the newly defined columns in the table definition will be added to the table
                // If no table with the same name exists, a table with the specified schema will be created
                store.DefineTable<ToDoItem>();

				// Initializes the sync context
                // Uses the default conflict handler, which fails on conflict
                await client.SyncContext.InitializeAsync(store);
                
                store = null;
			} 
            catch Exception ex)
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
                // Pushes all pending operations up to the remote table
                await client.SyncContext.PushAsync();

                if(pullData) 
                {
                    
                    // Creates a query for the current table
                    var query = todoTable.CreateQuery();
                    // Pulls all items that match the given query from the associated remote table
                    // Supports incremental sync
                    await todoTable.PullAsync("allTodoItems", query);
                }
            }
            catch(MobileServiceInvalidOperationException e)
            {
                Console.Error.WriteLine(@"Sync Failed: {0}", e.Message);
            }
#endif
        }

        public async Task<List<ToDoItem>> RefreshDataAsync()
        {
            try 
            {
#if OFFLINE_SYNC_ENABLED
                await SyncAsync(pullData: true);
#endif
                // Creates a query by applying the specified filter predicate
                Items = await todoTable.Where(todoItem => todoItem.Complete == false).ToListAsync();
            } 
            catch(MobileServiceInvalidOperationException e) 
            {
                Console.Error.WriteLine(@"ERROR {0}", e.Message);
                return null;
            }

            return Items;
        }

        public async Task InsertTodoItemAsync(ToDoItem todoItem)
        {
            try 
            {
                // Inserts an instance into the table
                await todoTable.InsertAsync(todoItem);
#if OFFLINE_SYNC_ENABLED
                await SyncAsync();
#endif
                Items.Add(todoItem);
            } 
            catch(MobileServiceInvalidOperationException e) 
            {
                Console.Error.WriteLine(@"ERROR {0}", e.Message);
            }
        }

        public async Task CompleteItemAsync(ToDoItem item)
        {
            try 
            {
                item.Complete = true;
                // Updates an instance in the table
                await todoTable.UpdateAsync(item);
#if OFFLINE_SYNC_ENABLED
                await SyncAsync();
#endif
                Items.Remove(item);
            } 
            catch(MobileServiceInvalidOperationException e) 
            {
                Console.Error.WriteLine(@"ERROR {0}", e.Message);
            }
        }
    }
}
```

## References
* [About Mobile Apps in Azure App Service](https://docs.microsoft.com/en-us/azure/app-service-mobile/app-service-mobile-value-prop).
* [Create a Windows app with an Azure backend](https://docs.microsoft.com/en-us/azure/app-service-mobile/app-service-mobile-windows-store-dotnet-get-started).
* [Enable offline sync for your Windows app](https://docs.microsoft.com/en-us/azure/app-service-mobile/app-service-mobile-windows-store-dotnet-get-started-offline-data).
