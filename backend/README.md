# Fitness Appointment App - Backend

Mashruucan waa backend-ka nidaamka ballan-a sameysiga jimicsiga (Fitness Appointment System). Waxaa loo dhisay iyadoo la isticmaalayo Node.js iyo Express.

## Teknoolojiyadaha la isticmaalay (Technologies Used)
- **Node.js**: Runtime environment
- **Express.js**: Web framework
- **MongoDB**: Database (NoSQL)
- **Mongoose**: ODM library
- **JWT (JSON Web Token)**: Authentication
- **Bcryptjs**: Password hashing

## Astaamaha (Features)
- Diiwaangelinta user-ka (User Registration)
- Soo gelitaanka user-ka (User Login)
- Ilaalinta wadooyinka (Route Protection)
- Ballan sameysiga (Booking Appointments)
- Helitaanka ballamada (Viewing Appointments)
- Joojinta ballamada (Cancelling Appointments)

## API Endpoints

### Authentication
- `POST /api/auth/register`: Diiwaangeli user cusub
- `POST /api/auth/login`: Soo gal user
- `GET /api/auth/me`: Hel xogta user-ka hadda jira (Private)

### Appointments
- `POST /api/appointments`: Samee ballan cusub (Private)
- `GET /api/appointments`: Hel ballamada user-ka (Private)
- `PUT /api/appointments/:id/cancel`: Jooji ballan (Private)

## Sida loo bilaabo (Setup Instructions)

1. **Soo deji mashruuca (Clone Repository)**
   ```bash
   git clone <repo-url>
   cd fitness-appointment-app/backend
   ```

2. **Dajiso waxyaabaha loo baahan yahay (Install Dependencies)**
   ```bash
   npm install
   ```

3. **Habeeyo Environment Variables (.env)**
   Nuqul ka samee `.env.example` una beddel `.env`, kadibna geli xogta saxda ah.
   ```
   NODE_ENV=development
   PORT=5000
   MONGO_URI=mongodb://localhost:27017/fitness_app
   JWT_SECRET=sirta_qarsoon
   ```

4. **Kici Server-ka (Run Server)**
   ```bash
   npm run dev
   ```

## Xubnaha Kooxda (Group Members)
- [Magaca Ardayga 1] - [ID]
- [Magaca Ardayga 2] - [ID]
- ...
