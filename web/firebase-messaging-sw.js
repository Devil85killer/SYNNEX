// firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: "AIzaSyBirVFruH43mFBaYzz7KPWD04JRhBG6B0",
  authDomain: "synnex-17430.firebaseapp.com",
  projectId: "synnex-17430",
  storageBucket: "synnex-17430.firebasestorage.app",
  messagingSenderId: "837907556855",
  appId: "1:837907556855:web:b9dff56479cc589c3366f2",
  measurementId: "G-E4020WS9MH"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Retrieve messaging
const messaging = firebase.messaging();

// Background Message Handling
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification.title || "New Message";
  const notificationOptions = {
    body: payload.notification.body || "You have a new notification",
    icon: '/icons/Icon-192.png', 
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});