import { initializeApp } from 'firebase/app';
import { getAuth, onAuthStateChanged, createUserWithEmailAndPassword, signInWithEmailAndPassword, sendPasswordResetEmail, signOut } from 'firebase/auth';

export const initFirebaseBackend = (config: any) => {
  initializeApp(config);
  const auth = getAuth();
  return new Promise((resolve, reject) => {
    onAuthStateChanged(auth, (user: any) => {
      resolve(user);
    });
  });
};

export const authenticateUser = (email: string, password: string) => {
  const auth = getAuth();
  return createUserWithEmailAndPassword(auth, email, password).then((user: any) => {
    const currentUser = auth.currentUser;
    return currentUser;
  });
};

export const signInUser = (email: string, password: string) => {
  const auth = getAuth();
  return signInWithEmailAndPassword(auth, email, password).then((user: any) => {
    const currentUser = auth.currentUser;
    return currentUser;
  });
};

export const resetPassword = (email: string) => {
  const auth = getAuth();
  return sendPasswordResetEmail(auth, email, {
    url: window.location.protocol + '//' + window.location.host + '/login'
  });
};

export const signOutUser = () => {
  const auth = getAuth();
  return signOut(auth);
};
