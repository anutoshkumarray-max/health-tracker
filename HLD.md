# Health Tracker — High-Level Design

## 1. Tech stack
- Frontend: React.js + JavaScript + HTML/CSS
- Backend: Node.js + Express.js
- Database: MySQL
- Auth: JWT + bcrypt password hashing
- Deployment: Vercel (frontend) + Render/Railway (backend) + managed MySQL

## 2. Architecture
Client (React) --HTTPS + JWT--> Express server
  -> Auth/validation middleware
  -> Controller (route handler)
  -> Service (business logic)
  -> MySQL (query scoped to req.user.id)
  -> Response back to client

## 3. Golden rule
Never trust a `user_id` sent from the frontend (body/params/query).
Always derive it from the verified JWT (`req.user.id`) set by auth middleware.

## 4. Data flow — example (Add weight record)
1. Client sends POST /api/weight with JWT in Authorization header + { weight_kg }
2. Auth middleware verifies JWT, attaches req.user.id
3. Validator checks weight_kg is a valid number
4. Controller calls weightService.addRecord(req.user.id, weight_kg)
5. Service runs parameterized INSERT into weight_records
6. Response: { id, weight_kg, recorded_at }

## 5. Database schema
See /database/schema.sql — full DDL with FKs and indexes.

Tables: users, profiles, weight_records, water_records, step_records,
sleep_records, goals, reminders, workouts, meals.

## 6. API contract (V1 core)
| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| POST | /api/auth/register | No | Create account |
| POST | /api/auth/login | No | Login + issue JWT |
| GET/PUT | /api/profile | Yes | Get/update profile |
| GET | /api/dashboard | Yes | Aggregated today's metrics |
| POST/GET | /api/weight | Yes | Add/list weight |
| PUT/DELETE | /api/weight/:id | Yes | Edit/delete weight |
| POST/GET | /api/water | Yes | Water tracking |
| POST/GET | /api/steps | Yes | Steps tracking |
| POST/GET | /api/sleep | Yes | Sleep tracking |
| POST/GET | /api/goals | Yes | Goal CRUD |
| PUT/DELETE | /api/goals/:id | Yes | Goal management |
| POST/GET | /api/reminders | Yes | Reminder CRUD |

## 7. Folder structure
health-tracker/
  frontend/src/{components,pages,hooks,services,utils}
  backend/src/{config,middleware,controllers,routes,services,validators}
  database/schema.sql
