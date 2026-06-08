import { environment } from '../../../environments/environment';
import { Injectable } from '@angular/core';

import { initFirebaseBackend } from '../../authUtils';

import { User } from '../models/auth.models';

@Injectable({ providedIn: 'root' })

export class AuthenticationService {

    user: User;

    constructor() {
    }

    /**
     * Returns the current user
     */
    public currentUser(): any {
        return initFirebaseBackend(environment.firebaseConfig).then((backend: any) => backend.getAuthenticatedUser());
    }

    /**
     * Performs the auth
     * @param email email of user
     * @param password password of user
     */
    login(email: string, password: string) {
        return initFirebaseBackend(environment.firebaseConfig).then((backend: any) => backend.loginUser(email, password)).then((response: any) => {
            const user = response;
            return user;
        });
    }

    /**
     * Performs the register
     * @param email email
     * @param password password
     */
    register(email: string, password: string) {
        return initFirebaseBackend(environment.firebaseConfig).then((backend: any) => backend.registerUser(email, password)).then((response: any) => {
            const user = response;
            return user;
        });
    }

    /**
     * Reset password
     * @param email email
     */
    resetPassword(email: string) {
        return initFirebaseBackend(environment.firebaseConfig).then((backend: any) => backend.forgetPassword(email)).then((response: any) => {
            const message = response.data;
            return message;
        });
    }

    /**
     * Logout the user
     */
    logout() {
        initFirebaseBackend(environment.firebaseConfig).then((backend: any) => backend.logout());
    }
}
