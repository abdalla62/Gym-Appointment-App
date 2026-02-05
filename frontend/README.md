Gym / Appointment App waa barnaamij loogu talagalay in lagu fududeeyo jadwalka tababarayaasha (trainers) iyo macaamiisha (users) ee gym-ka. App-kan wuxuu u oggolaanayaa users inay dooran karaan tababare, sameeyaan booking, oo ay arki karaan ballamaha ay qabsadeen, halka trainers ay arki karaan ballamaha ay leeyihiin iyo dadka ay tababaraan.

Barnaamijkan waxaa lagu dhisay Node.js, Express, iyo MongoDB, iyadoo la adeegsanayo JWT authentication, role-based access, iyo centralized error handling.

Features / Astaamaha

User Authentication & Authorization

Isdiiwaangelin iyo login users iyo trainers.

JWT token authentication.

Role-based access control (user, trainer, admin).

Trainers Management

List gareynta tababarayaasha.

Aragtida availability (waqtiga faaruqa ah).

Trainers waxay arki karaan ballamaha ay leeyihiin.

Appointments / Bookings

Users waxay sameyn karaan booking oo ku xiran tababare iyo waqti.

Validation-ka waqtiga si looga hortago conflicts.

Users waxay arki karaan ballamahooda.

Validation & Middlewares

Hubinta xogta laga soo dirayo frontend.

Middleware ka shaqeeya authentication, authorization, iyo error handling.

Centralized Error Handling

Hal meel oo lagu maamulo dhammaan errors-ka.

Response uniform ah, app-ka ma crash-gareeyo.

Architecture / Qaab-dhismeedka

1. Models (Database)

Users, Trainers, Appointments

Waxay kaydiyaan xogta iyo xiriirka u dhexeeya.

2. Controllers (Business Logic)

Qaabilsan fulinta request-ka iyo la hadalka database-ka.

Hubinta xeerarka ganacsiga (business rules), sida booking conflict.

3. Routes

Endpoint-yada app-ka.

Kala soocidda users, trainers, iyo bookings.

4. Middlewares

Authentication: JWT token hubinta.

Authorization: Role-based access control.

Error handling: Centralized error responses.

5. Validators

Hubinta xogta laga soo diro frontend, sida email, password, iyo waqtiyada booking.

Workflow / Sida uu u shaqeeyo

User-ku wuxuu login/register sameeyaa.

User-ka wuxuu dooranayaa trainer iyo time slot.

Validator hubiyaa xogta.

Middleware hubiyaa authentication & authorization.

Controller wuxuu hubiyaa:

Trainer ma faaruq yahay waqtigaas?

User ma horey u qabsaday waqti isku mid ah?

Haddii sax, waxaa la kaydiyaa booking.

Response ayaa la soo celinayaa.

Haddii error dhaco, waxaa maamula centralized error handler.

Business Rules / Xeerarka App-ka

Hal trainer hal user waqti kasta.

Hal user ma qabsan karo labo ballan isku waqti ah.

Booking waa in uu mustaqbal yahay.

Trainers ma samayn karaan booking, kaliya arki karaan.

Technologies / Tiknoolajiyada La Adeegsaday

Node.js – Backend runtime environment

Express.js – Web framework

MongoDB / Mongoose – Database

JWT – Authentication

Express Validator – Input validation

Centralized Error Handling – Error management

Middleware Architecture – Security & request flow
