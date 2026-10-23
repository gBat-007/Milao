# Milao

Milao is an AI-powered planning assistant built for iOS 26+ using Apple's Foundation Models framework. Using AI-guided questioning, it helps groups decide on optimal meeting locations as per their requirements without excessive decision-making, especially meant for large cities with many options available. All AI processing happens on-device, while Firebase Realtime enables instant sync between attendees. Our target audience is planning simple, casual events, perhaps for a club or birthday, as we've personally noticed these can sometimes become quite a hassle when considering all your needs!

## Why Not Just Use a Group Chat Application, ChatGPT, and Google Maps?
Because if you ask ChatGPT for your optimal location plan, most implicit requirements may not even come to your mind (like you assuming that when you say 'arcade' you mean one with a bowling alley because that's common in your country). In Milao, the on-device LLM will consider local context and ask guiding multiple-choice questions, taking all the overthinking out of the planning. Plus, our algorithm will consider equidistance from all attendees, and we're working on refining these features as we go; and all of that in one app! 

## I Don't Want to Share My Location
You always have the option for approximate location or manual input: say you want the app to search through downtown Chicago, you can just put that rather than any exact location.

## I Still Need to Use a Calendar Though
Nope, we'll by default set a live activity onto your iPhone showing time left til the event and you can make an alarm ring a certain time before your event! You can even check this live activity and the vital event details directly via the Apple Watch Companion app on the go. For multi-location events, we plan to also add easy timing features that consider transportation!

## And If I Switch Devices?
We have Sign in With Google and Apple set up for identification -- so if you switch devices, all your data will sync by default! Plus, at any time you can delete your account and stored data with a simple click!

## But Don't Apps like Lu.ma, Uber Eats for restaurants, etc. handle event management in most ways we need?
That's just it. Event _management_. Our app, though it has many event management features to make your life easier, is built on the core of making event _planning_ less work; in essence, figuring out where to go. Plus, having multiple locations for casual events is fairly common yet rarely handled by other applications.

## Ok, I Want this App.
We're still in our developer testing phase, we'll release a TestFlight build soon!
