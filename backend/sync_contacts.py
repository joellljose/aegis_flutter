import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate('serviceAccountKey.json')
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()

contacts = [
    {
        'contact_id': 'tc_joel_responder',
        'owner_uid': 'shBlYl3IplYazxi037LnFykmIa93',
        'contact_name': 'Joel',
        'phone': '9207801787',
        'relationship': 'Family',
        'priority': 1,
        'channels': ['WhatsApp', 'SMS', 'CALL'],
        'status': 'STANDBY',
        'invitation_status': 'accepted',
        'created_at': '2026-10-28T20:30:00Z',
        'updated_at': '2026-10-28T20:30:00Z',
    },
    {
        'contact_id': 'tc_adithyan_responder',
        'owner_uid': 'shBlYl3IplYazxi037LnFykmIa93',
        'contact_name': 'Adithyan',
        'phone': '123456789',
        'relationship': 'Family',
        'priority': 1,
        'channels': ['WhatsApp', 'SMS', 'CALL'],
        'status': 'STANDBY',
        'invitation_status': 'accepted',
        'created_at': '2026-10-28T20:30:00Z',
        'updated_at': '2026-10-28T20:30:00Z',
    }
]

for c in contacts:
    db.collection('trusted_contacts').document(c['contact_id']).set(c, merge=True)
    print('Saved contact to trusted_contacts:', c['contact_name'], c['contact_id'])

db.collection('users').document('shBlYl3IplYazxi037LnFykmIa93').set({'contacts': contacts}, merge=True)
print('Updated users/shBlYl3IplYazxi037LnFykmIa93 contacts array')

docs = list(db.collection('trusted_contacts').where('owner_uid', '==', 'shBlYl3IplYazxi037LnFykmIa93').stream())
print('Total contacts in Firestore trusted_contacts for Joel:', len(docs))
for d in docs:
    data = d.to_dict()
    print(' - Document ID:', d.id, '| Name:', data.get('contact_name'), '| Phone:', data.get('phone'), '| Relation:', data.get('relationship'), '| Priority:', data.get('priority'))
