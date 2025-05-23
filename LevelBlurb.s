*********************************************************************************************

                          opt     P=68020
              
*********************************************************************************************
; Inline source
; For : ControlLoop.s
; Description : Level descriptions + end text
*********************************************************************************************
                          cnop    0,32

MpMasterText:
;                                      01234567890123456789012345678901234567890123456789012345678901234567890123456789
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"Master computer                                                                 "
                          dc.b    0,1,"Waiting..                                                                       "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "

                          cnop    0,32
    
MpSlaveText:
;                                      01234567890123456789012345678901234567890123456789012345678901234567890123456789
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"Slave computer                                                                  "
                          dc.b    0,1,"Connecting..                                                                    "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "

                          cnop    0,32
    
LEVELTEXT:
; Start of level one:
;                                      01234567890123456789012345678901234567890123456789012345678901234567890123456789
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"The base looms dead and silent in front of me, blotting out the sky. The main   "
                          dc.b    0,1,"entrance is out of the question; choked with rubble and bodies, not all of them "
                          dc.b    0,1,"human. I didn't look too closely. Picking my way through the debris around the  "
                          dc.b    0,1,"perimeter, I find a way in: a service entrance located in a storage bay below   "
                          dc.b    0,1,"ground level. I grip my pulse rifle tightly and lower myself into the pit.      "
                          dc.b    0,1,"No turning back now.                                                            "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
 
;Start of level two:
;                                      0123456789012345678901234567890123456789
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"Taking my life in my hands, I jump into the teleporter, hoping it will take me  "
                          dc.b    0,1,"further into the complex, although I'm pretty hazy about what I'm going to do   "
                          dc.b    0,1,"when I get there. As I materialize, however, my hopes sink. The transporter was "
                          dc.b    0,1,"intended for freight only, and I find myself in a huge empty storage room.      "
                          dc.b    0,1,"Looks like I'll have to find some other way in. The Breed howl their greetings  "
                          dc.b    0,1,"as I stride forward....                                                         "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
 
;Start of level three:
;                                      0123456789012345678901234567890123456789
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"In the computer room I try to call up a map, or blueprint, or anything to tell  "
                          dc.b    0,1,"me where I ought to be heading. The only plans I can access from this terminal, "
                          dc.b    0,1,"however, are some schematics for the sewer system. Poring over them I find a    "
                          dc.b    0,1,"possible route: there's a waste outlet I can reach from my current location     "
                          dc.b    0,1,"which seems to lead further into the complex. Unfortunately, the sewers are     "
                          dc.b    0,1,"partially flooded most of he time, and sloshing through thigh-deep sewage is not"
                          dc.b    0,1,"my idea  of fun. It seems to be the only way forward, though, and retreat into  "
                          dc.b    0,1,"the infested passages behind me is an even less inviting prospect....           "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
 

;Start of level four
;                                      0123456789012345678901234567890123456789
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"Shivering and sweating at the same time, I try to shake the icy water from my   "
                          dc.b    0,1,"clothes and take in my new surroundings. I think I must be somewhere in the     "
                          dc.b    0,1,"research department; the token military presence I commanded here was always    "
                          dc.b    0,1,"discouraged from poking their noses into matters that 'didn't concern them.'    "
                          dc.b    0,1,"Looking around I catch my breath: this place is enormous; even bigger than I had"
                          dc.b    0,1,"thought. The purpose of this area eludes me; the cavernous rooms and winding    "
                          dc.b    0,1,"staircases serve no immediately visible function. Stepping over the huddled body"
                          dc.b    0,1,"of another luckless soldier I back up against the cold stone wall and edge      "
                          dc.b    0,1,"towards the corner. The hate-filled cries of the Breed echo through the dim     "
                          dc.b    0,1,"vaulted chambers; this strange place is anything but deserted....               "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
 
;Start of level five
;                                      0123456789012345678901234567890123456789
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"As I pause for breath I notice a sign on the wall nearby:                       "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"COMBAT TEST ARENA: ALPHA                                                        "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"pointing back the way I have just come. Now it makes more sense! All those rooms"
                          dc.b    0,1,"and walkways were some sort of testing ground for - what? The grotesque         "
                          dc.b    0,1,"experiments now littering the halls with their bodies? Or something else -      "
                          dc.b    0,1,"something I haven't seen yet, perhaps? I glance around nervously as the thought "
                          dc.b    0,1,"takes shape, but as my eyes adjust to the gloom I see nothing but bank upon bank"
                          dc.b    0,1,"of computers stretching as far as the eye can see. Now this is more like it! If "
                          dc.b    0,1,"I can  gain access somehow, I might be able to find a way to escape! A databank "
                          dc.b    0,1,"this size must hold all sorts of useful information. There are no terminals     "
                          dc.b    0,1,"though. Maybe if I find my way out I can hack in from somewhere nearby.         "
                          dc.b    0,1,"A gurgling, half-human grunt behind me makes me spin around, heart pounding.... "
                          dc.b    0,0,"                                                                                "
 
;Start of level six:
;                                      0123456789012345678901234567890123456789
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"As I had hoped, there is a room just outside the entrance to the computer store "
                          dc.b    0,1,"with an operational terminal. After nearly two hours of desperate hacking, the  "
                          dc.b    0,1,"computers grudgingly furnish me with the information I need: a replay of the    "
                          dc.b    0,1,"message my second in command sent to our superiors off-planet when the outbreak "
                          dc.b    0,1,"became unstoppable. He was planning to escape on our private shuttle, after     "
                          dc.b    0,1,"disabling the cooling system on the main reactor. I watch in dismay as his      "
                          dc.b    0,1,"message is cut short; the horde of slavering Breed which break down the door and"
                          dc.b    0,1,"devour him alive pay no heed to the camera still recording his screams. A split "
                          dc.b    0,1,"second later the net security catches up with my activities and the terminal    "
                          dc.b    0,1,"shuts down. I know what I must do. A reactor meltdown would blow this whole     "
                          dc.b    0,1,"wretched place into orbit and the Breed with it. And I might just live to see it"
                          dc.b    0,1,"happen. But to go any further I need a high-clearance access card: the security "
                          dc.b    0,1,"systems here are not responding to my palm print or retina scan. The Breed howl "
                          dc.b    0,1,"mockingly as I set out to find it....                                           "
                          dc.b    0,0,"                                                                                "
  
;Start of level seven:
;                                      0123456789012345678901234567890123456789
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"I found the access card, along with the remains of its owner. What posessed him "
                          dc.b    0,1,"to flee into the mines no-one will ever know. His mildly surprised face gazing  "
                          dc.b    0,1,"up at me from its watery hiding place is an image I have difficulty banishing   "
                          dc.b    0,1,"from my mind. Along with many others. The transporter takes me down and down,   "
                          dc.b    0,1,"into the substructure of the base. According to my route plan, I should be able "
                          dc.b    0,1,"to get back into the main building further on, saving time and avoiding some    "
                          dc.b    0,1,"dangerous areas. This way is far from safe though; a lot of fuel lines go       "
                          dc.b    0,1,"through this area....                                                           "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
 
; Start of level eight:
;                                      0123456789012345678901234567890123456789
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"As soon as I step onto the transporter I realise something is wrong. The        "
                          dc.b    0,1,"instrument panel dangles from a jumble of wires; sparks and smoke issue from    "
                          dc.b    0,1,"within. I curse loudly and lunge for the door; a faulty transporter can be      "
                          dc.b    0,1,"lethal. But before I can get out, something within the scorched mess of         "
                          dc.b    0,1,"electronics crackles and I am - somewhere else.                                 "
                          dc.b    0,1,"After checking that I am, in fact, still whole, I look uneasily around myself.  "
                          dc.b    0,1,"An icy chill settles over my heart as I see a sign - scored and dented by some  "
                          dc.b    0,1,"massive impact - which reads:                                                   "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"COMBAT TEST ARENA: GAMMA                                                        "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"The huge exit door is locked. I'm going to have to find the key. Hopefully      "
                          dc.b    0,1,"whatever they were testing isn't still here....                                 "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "

;Start of level nine:
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"Glad to be alive, I stumble out of the combat arena and collapse, the door      "
                          dc.b    0,1,"slamming shut behind me. When I come to to my senses again, I find myself on    "
                          dc.b    0,1,"some sort of lift. The only way seems to be upwards, but I have no idea where it"
                          dc.b    0,1,"will take me. My only hope is to find another terminal and get back on track.   "
                          dc.b    0,1,"Exhausted, I bandage my wounds as best I can and stagger to my feet. I press a  "
                          dc.b    0,1,"nearby button and the lift judders upwards in response. I wipe my sweaty palms  "
                          dc.b    0,1,"on my jacket and grip my gun more tightly - things are too quiet up there....   "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
  
;Start of level ten:
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"I am beginning to think that there is simply no end to this hellish place.      "
                          dc.b    0,1,"My fevered imagination conjures up an entire planet riddled with these dark     "
                          dc.b    0,1,"corridors and rooms, empty and deserted except for the screams of the Breed.    "
                          dc.b    0,1,"With difficulty I get a grip on myself. A barely readable notice on the wall    "
                          dc.b    0,1,"gives me hope: one of the facilities it mentions, the administration block, was "
                          dc.b    0,1,"right near the route the computer gave me. Straightening with new purpose, I set"
                          dc.b    0,1,"my jaw and continue. But in the shadows ahead, the breed reach out for me....   "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
 
;Start of level eleven:
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"I made it! The transporter dumps me in a brightly-lit room in the administration"
                          dc.b    0,1,"centre. Supplies are at hand, and I waste no time provisioning myself. All that "
                          dc.b    0,1,"remains is for me to find my way out of here and I'll be right on top of the    "
                          dc.b    0,1,"reactor core! I press the panel which opens the door with renewed hope; I might "
                          dc.b    0,1,"just beat them yet....                                                          "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
 
; Start of level twelve:
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"I slam the door of the admin block behind me, and stare about wildly. I hadn't  "
                          dc.b    0,1,"expected so much resistance; what has happened here? I can only assume that I am"
                          dc.b    0,1,"approaching the centre of the infestation. But there! On the wall opposite: a   "
                          dc.b    0,1,"sign pointing the way to the reactor control room! I lurch off in the direction "
                          dc.b    0,1,"it points, but am brought up short with a shout of despair. The whole corridor  "
                          dc.b    0,1,"is blocked with rubble! I punch the wall in anger and frustration, but I will   "
                          dc.b    0,1,"not - cannot - give up now. I look around desperately; a wall plan nearby shows "
                          dc.b    0,1,"no other connecting corridors, but there is an alternative route: a winding     "
                          dc.b    0,1,"tunnel leading to a deep borehole. From there I can ride a lift back up to the  "
                          dc.b    0,1,"surface and gain access to the reactor from the other side. I stare for a while "
                          dc.b    0,1,"at the mountain of debris, mere yards on the other side of which is my goal,    "
                          dc.b    0,1,"then turn my back and walk away....                                             "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "

;Start of level thirteen:
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"The lift takes me up to ground level, but what had been marked as a passageway  "
                          dc.b    0,1,"on the plans turns out to be still under construction. Wetting a finger and     "
                          dc.b    0,1,"holding it aloft I find that there is indeed a sluggish current of air from the "
                          dc.b    0,1,"black passage ahead, but the labyrinth of caves also echoes with the cries of   "
                          dc.b    0,1,"the enemy. I briefly consider returning to the pit and trying to find a         "
                          dc.b    0,1,"different way, but shudder and dismiss the idea immediately. Gritting my teeth, "
                          dc.b    0,1,"I plunge into the darkness with guns ablaze....                                 "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "

;Start of level fourteen:
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"Getting to the reactor control centre proves to be only half the battle. The    "
                          dc.b    0,1,"place is a maze of corridors and rooms centred around the - maddeningly close   "
                          dc.b    0,1,"but still unreachable - reactor core itself. Somehow I must raise the walk-ways "
                          dc.b    0,1,"leading to the cooling system and extract it from the core. Then I'll have about"
                          dc.b    0,1,"two hours to get into orbit before meltdown occurs. If the shuttle is flight-   "
                          dc.b    0,1,"ready, that's no problem. If not...                                             "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
 
;Start of level fifteen:
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"Mission accomplished, I pelt out of the reactor core towards the command centre,"
                          dc.b    0,1,"which lies some distance from the main base. First though I have to get out of  "
                          dc.b    0,1,"the power plant, and with fuel coming to the boil in the groaning pipes all     "
                          dc.b    0,1,"around me, that's easier said than done. The corridors here are thick with the  "
                          dc.b    0,1,"Breed too, and I'm going to have to wade right through them. My own scream of   "
                          dc.b    0,1,"rage and hate rising to challenge the horde, I charge the lot of them....       "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,0,"                                                                                "
 
;Start of level sixteen:
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"Slamming the door shut on the grasping claws and rending teeth, silence engulfs "
                          dc.b    0,1,"me. I turn and lean on the wall, heaving a sigh of relief. The reactor is behind"
                          dc.b    0,1,"me now, and all that remains is for me to find the shuttle and get out of here. "
                          dc.b    0,1,"Grabbing as much equipment as I can carry, I set off, the nearness of my goal   "
                          dc.b    0,1,"spurring me on. I pass a sign:                                                  "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"COMMAND CENTRE: AUTHORIZED PERSONNEL ONLY. CLEARANCE                            "
                          dc.b    0,1,"MU T BE OB AINED FRO                                                            "
                          dc.b    0,0,"                                                                                "
                          dc.b    0,1,"the rest of it is unreadable; a charred mess. I resolve to be on the look out   "
                          dc.b    0,1,"for anyone who looks likely to hold a passkey. As I step outside I can see the  "
                          dc.b    0,1,"command centre, the only access from this side seemingly via a gantry high      "
                          dc.b    0,1,"overhead. Somewhere there must be a way up to that gantry. And somewhere there's"
                          dc.b    0,1,"a passkey to get me inside....                                                  "
                          dc.b    0,0,"                                                                                "

; End of game text:
;                                      0123456789012345678901234567890123456789
ENDGAMETEXT:
                          dc.b    0,1,"Dazed and shaking, I stagger along the gloomy passages. The emergency shuttle   "
                          dc.b    0,1,"should be - must be - in this area. I round one final corner and there, glinting"
                          dc.b    0,1,"in the twilight, stands my escape route. I am on the verge of collapse; my legs "
                          dc.b    0,1,"giving out, my arms torn by the Breed and scorched by the red-hot casing of the "
                          dc.b    0,1,"gun dangling limply by my side. But I am alive.                                 "
                          dc.b    0,1,"I drag myself to the accelleration couch and painfully strap myself in.         "
                          dc.b    0,1,"Everything seems to be moving in slow motion; the cockpit spins sickeningly     "
                          dc.b    0,1,"around me as I reach for the launch controls.... there! I let myself fall back, "
                          dc.b    0,1,"utterly exhausted. The quiet tones of the shipboard computer announces the      "
                          dc.b    0,1,"countdown, but for me the words are fading as if into a great distance.         "
                          dc.b    0,1,"Something makes a dull thudding sound against the hull; the engines starting?   "
                          dc.b    0,1,"No, they cut in a moment later with a muted roar. The computer chatters to      "
                          dc.b    0,1,"itself and flashes coloured lights at me; I must have left the airlock open. No "
                          dc.b    0,1,"matter. The computer will close it automatically before liftoff. I can stay     "
                          dc.b    0,1,"awake no longer. All I can think as I sink into unconsciousness is that I'm     "
                          dc.b    0,1,"feeling very... very... heavy...                                                "

;END OF GAME PLAN:

; load and start end of game music.
; Fade up End of game text above.
; Wait for mouse/joystick/keyboard click.
; Fade up "THE END", pause and fade down.
; Fade up "ALIEN BREED 3D", pause and fade
; down.
; Fade up "Brought to you by"
; slow scroll:

ENDOFGAMESCROLL:
;                                      01234567890123456789012345678901234567890123456789012345678901234567890123456789
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
  
                          dc.b    2,1,"ALIEN BREED 3D                                                                  "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    0,1,"A Team 17 Production                                                            "
                          dc.b    -1,-1
                          dc.b    0,1,"of a                                                                            "
                          dc.b    -1,-1
                          dc.b    0,1,"Short But Purple Software/Team 17                                               "
                          dc.b    -1,-1
                          dc.b    0,1,"game                                                                            "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
 
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    2,1,"THE CAST:                                                                       "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    2,1,"Arnold the Alien                                                                "
                          dc.b    -1,-1
                          dc.b    0,1,"Initially enthusiastic about his role, Arnold was mildly put out at being the   "
                          dc.b    0,1,"only unarmed combatant, and hence his vain attempts to sidle out of the line of "
                          dc.b    0,1,"fire. Arnold was also somewhat dismayed by the stylish, fashion conscious, but  "
                          dc.b    0,1,"distressingly prominent shade of bright red his contract demanded he wear.      "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    2,1,"Melvin the Mutant                                                               "
                          dc.b    -1,-1
                          dc.b    0,1,"Melvin showed off his acting ability to the full in this, his latest appearance,"
  
                          dc.b    0,1,"in which he played no fewer than three roles simultaneously: a pistol-wielding  "
                          dc.b    0,1,"psychotic soldier, a plasma-gun wielding psychotic soldier, and a shotgun       "
                          dc.b    0,1,"wielding psychotic soldier. He brushes aside claims that the difference between "
                          dc.b    0,1,"the roles was purely cosmetic, saying that each required a completely different "
                          dc.b    0,1,"mind-set, and regards it as his most challenging role to date.                  "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    2,1,"Frank the Floating Thing                                                        "
                          dc.b    -1,-1
                          dc.b    0,1,"Another versatile actor, Frank spent a lot of time getting into his role, force-"
                          dc.b    0,1,"feeding himself tons of weight gain pills and full-fat milkshakes so as to gain "
                          dc.b    0,1,"personal experience of the lifestyle of the huge blubbery floating mound he     "
                          dc.b    0,1,"portrays. Now that's commitment for you!                                        "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    2,1,"Worm Dude                                                                       "
                          dc.w    -1,-1
                          dc.b    0,1,"Teased at a tender age for his delicate pastel colouring, Worm grew up into the "
                          dc.b    0,1,"bad boy of the Hollywood jetset. It is rumoured that he sawed off both his arms "
                          dc.b    0,1,"and replaced them with powerful energy weapons in an attempt to upstage the     "
                          dc.b    0,1,"other members of the cast. After his success in AB3D, he says it is 'doubtful'  "
                          dc.b    0,1,"that he will return to his previous employment, serving in a fast food          "
                          dc.b    0,1,"establishment.                                                                  "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    2,1,"Theresa Tentacle                                                                "
                          dc.b    -1,-1
                          dc.b    0,1,"Theresa has the honour of wearing the most make-up of any cast member in this   "
                          dc.b    0,1,"production, or any other production for that matter. Terrence was fitted with a "
                          dc.b    0,1,"a complete alien suit which moved around in response to her wrigglings. She     "
                          dc.b    0,1,"remarks that the hours spent getting in and out of the suit were 'worth it'.    "
                          dc.b    0,1,"She is confident that her role in AB3D will get her noticed by other            "
                          dc.b    0,1,"entertainment companies, and that this will be only the first of many openings  "
                          dc.b    0,1,"for her.                                                                        "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    2,1,"Eric the Eyeball                                                                "
                          dc.b    -1,-1
                          dc.b    0,1,"Eric was thrilled to discover he would be actually flying in his new role. He   "
                          dc.b    0,1,"says it is something he has always wanted to try, particularly if he could spit "
                          dc.b    0,1,"fire at the same time. When the offer came up, he rolled at it straight away.   "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    2,1,"Robbie the Robot                                                                "
                          dc.b    -1,-1
                          dc.b    0,1,"Big, ugly, aggressive and none too bright, that's Robbie all over.              "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    2,1,"Rupert the Really REALLY Big Thing on the Last Level                            "
                          dc.b    -1,-1
                          dc.b    0,1,"Rupert was delighted to finally find a role which he fit comfortably. Previous  "
                          dc.b    0,1,"attempts to integrate him into the cast of films has, inevitably perhaps,       "
                          dc.b    0,1,"involved enormous trenches, improbably high stacks of boxes or, in extreme cases"
                          dc.b    0,1,"amputation of the lower body in order to bring him down to the level of other   "
                          dc.b    0,1,"actors.                                                                         "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    2,1,"THE CREW:                                                                       "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    0,1,"Programming, Game Code, Graphics, Game Design, Level Editor & Manual            "
                          dc.b    -1,-1
                          dc.b    1,1,"Andrew Clitheroe                                                                "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    0,1,"Alien Design, Alien Graphics & Weapon Graphics                                  "
                          dc.b    -1,-1
                          dc.b    1,1,"Michael Green                                                                   "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    0,1,"Serial Link, 3D Object Editor and 3D Object Design                              "
                          dc.b    -1,-1
                          dc.b    1,1,"Charles Blessing                                                                "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    0,1,"Music and Sound Effects                                                         "
                          dc.b    -1,-1
                          dc.b    1,1,"Bjorn Lynne                                                                     "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    0,1,"Alien Graphics                                                                  "
                          dc.b    -1,-1
                          dc.b    1,1,"Simon Butler                                                                    "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    0,1,"Creative Director                                                               "
                          dc.b    -1,-1
                          dc.b    1,1,"Martyn Brown                                                                    "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    0,1,"Project Manager and Manual                                                      "
                          dc.b    -1,-1
                          dc.b    1,1,"Martin O'Donnell                                                                "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    0,1,"Cover Illustration and Logo                                                     "
                          dc.b    -1,-1
                          dc.b    1,1,"Kevin Jenkins                                                                   "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    0,1,"Packaging and Manual Design                                                     "
                          dc.b    -1,-1
                          dc.b    1,1,"Paul Sharpe                                                                     "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    0,1,"QA and Playtest                                                                 "
                          dc.b    -1,-1
                          dc.b    1,1,"Phil Quirke-Webster & The Wolves                                                "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    0,1,"A 'Who To Blame' guide to the levels:                                           "
                          dc.b    -1,-1
                          dc.b    2,1,"The Gate                    Andrew Clitheroe                                    "
                          dc.b    2,1,"Storage Bay                      Ben Chanter                                    "
                          dc.b    2,1,"Sewer Network                    Ben Chanter                                    "
                          dc.b    2,1,"The Courtyard               Andrew Clitheroe                                    "
                          dc.b    2,1,"System Purge                Andrew Clitheroe                                    "
                          dc.b    2,1,"The Mines                   Andrew Clitheroe                                    "
                          dc.b    2,1,"The Furnace                    Michael Green                                    "
                          dc.b    2,1,"Test Arena Gamma                 Jackie Lang                                    "
                          dc.b    2,1,"Surface Zone                Andrew Clitheroe                                    "
                          dc.b    2,1,"Training Area                    Jackie Lang                                    "
                          dc.b    2,1,"Admin Block                 Andrew Clitheroe                                    "
                          dc.b    2,1,"The Pit                          Kai Barrett                                    "
                          dc.b    2,1,"Strata                           Ben Chanter                                    "
                          dc.b    2,1,"Reactor Core                Charles Blessing                                    "
                          dc.b    2,1,"Cooling Tower               Andrew Clitheroe                                    "
                          dc.b    2,1,"Command Centre              Andrew Clitheroe                                    "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    0,1,"Thanks to all those who bought this game; presumably you enjoyed it enough to   "
                          dc.b    0,1,"bother finishing it. A lot of work went into it, probably more than you think.  "
                          dc.b    0,1,"It took a very long time to get just right. I hope you think it was worth the   "
                          dc.b    0,1,"wait.                                                                           "
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
                          dc.b    -1,-1
 
; Alien design, Alien graphics, Weapon graphics and
;                    Title screen:
;                    Michael Green

;                   Other graphics: 
;                  Andrew Clitheroe

;      Serial link code, 3d object editor and 3d
;                   object design:
;                  Charles Blessing

;            All music and sound effects:
;                  Bjorn Lyndstrom(?)

;                   Level design:

;   The Gate                    Andrew Clitheroe
;   Storage Bay 2                    Ben Chanter
;   Floodwater                       Ben Chanter
;   The Courtyard               Andrew Clitheroe
;   System Purge                Andrew Clitheroe
;   The Mines                   Andrew Clitheroe
;   Maintenance Level              Michael Green
;   Test Arena Gamma                 Jackie Lang
;   The Pit                     Andrew Clitheroe
;   Jackie's level                   Jackie Lang
;   Admin Block                 Andrew Clitheroe
;   The Gauntlet                     Kai Barrett
;   Minos                            Ben Chanter
;   Reactor Core                Charles Blessing
;   Meltdown                    Andrew Clitheroe
;   Command Centre              Andrew Clitheroe

;                Project supervisors: 
;                   Martin Brown
;                 Martin O'Donnell(?)

;                   Team 17 1995

;                 An SBP production

;                     Starring:
;              (In order of appearance)

;                 Arnold the Alien

; Initially enthusiastic about his role, Arnold was
; mildly put out at being the only unarmed combatant
; and hence his vain attempts to sidle out of the 
; line of fire. Arnold was also somewhat dismayed by
;the stylish and fashion-conscious, but otherwise
;unfortunately visible shade of bright red his
; contract demanded he wear. 

;                Melvin the Mutant

; Melvin showed off his acting ability to the full in
;this, his latest appearance, in which he played no
;fewer than three roles simultaneously: a pistol-
;wielding psychotic soldier, a plasma-gun wielding
;psychotic soldier, and a shotgun wielding psychotic
;soldier. He brushes aside claims that the difference
;between the roles was purely cosmetic, saying that
;each required a totally different mind-set, and that
;he regarded it as his most challenging role to date.

;            Frank the Floating Thing

;   Another versatile actor, Frank spent a lot of
; time getting into his role, force-feeding himself
; tons of weight gain pills and full-fat milkshakes
; so as to gain an insight into the lifestyle of the
; huge blubbery floating mound he plays. Now that's
; commitment for you!

;                    Worm Dude

; Teased at a tender age for his delicate pastel
; colouring, Worm grew up into the bad boy of the
; Hollywood jetset. It is rumoured that he sawed off
; both his arms and replaced them with large energy
; weapons in an attempt to upstage the other members
; of the cast.

;             Terrence the Tentacle

; Terrence has the honour of wearing the most make-up
; of any cast member in this production, or any other
; production for that matter. Terrence was fitted with
; a complete alien suit which moved around in response
; to his wrigglings. He remarks that the hours spent
; getting in and out of the suit were 'worth it'.

;                Eric the Eyeball

; Eric was thrilled to discover he would be actually
; flying in his new role. He says it is something he
; has always wanted to try, particularly if he could
; spit fire at the same time. When the offer came up,
; he rolled at it straight away.

;                Robbie the Robot

; Big, ugly, aggressive and none too bright, that's
;                Robbie all over.

;
ENDOFEND: