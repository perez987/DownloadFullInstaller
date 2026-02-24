# App is damaged and can't be opened

The conditions Apple imposes to maintain user security and privacy are becoming increasingly strict. This, of course, benefits users but it has drawbacks.

When a file is downloaded from the Internet, an extended attribute named `com.apple.quarantine` is added to it so that Gatekeeper requests confirmation before executing them.

In pre-Sequoia versions, the Gatekeeper warning for files downloaded from the Internet had a simple solution: accepting the warning when opening the file or right-clicking on the file >> Open.

But in Sequoia and Tahoe, the warning is more serious and might upset the user. It may display this message:
<br>`The application is damaged and cannot be opened.`<br>
Or this one:
<br>`Could not verify that Download Full Installer does not contain malicious software.`<br>
With the recommendation in both cases to move the file to the Trash.

This is the warning that appears when the app is not digitally signed or notarized by Apple; in which case, the warning is more benign, reminiscent of the pre-Sequoia versions.

**Note**: You don't need to remove the attribute if you download the source code, compile the app with Xcode, and save the product for regular use. When you compile an app in Xcode and set it to Sign to Run Locally, Xcode signs it with a trusted local certificate so the system can run it. If `Hardened Runtime` is disabled, the app doesn't need Apple's certification and will continue to function normally on your Mac. That's why you don't see the security warning.

Currently, an Apple Developer account is required to digitally sign or notarize Mac applications. However, many developers don't want to register with the Apple Developer Program, either because of the cost or because they develop small apps that are distributed for free.

This is the case with many of the apps we publish as amateurs, signed ad-hoc and not notarized. Although the source code for these types of applications is usually available and can be explored to determine if there are conditions that weaken security, this warning may raise some suspicions. 

Users who have Gatekeeper disabled will not see this warning. However, disabling Gatekeeper globally to run a single application is not a valid recommendation.

How to fix this issue?

## Disable Gatekeeper (NOT RECOMMENDED)

1. Open the Terminal app on your Mac and run the following command: `sudo spctl —master-disable`<br>
Note: in recent macOS versions, the argument `—master-disable` has been changed to `—global-disable`
2.  Go to "System Settings"->"Privacy & Security"->"Security" -> Allow applications from "Everywhere"
3. Both arguments can revert this and enable Gatekeeper again:  `sudo spctl —master-enable`  `sudo spctl —global-enable`
4. From this point on, downloaded apps will run without security prompts.

> Disabling Gatekeeper globally to run a single application is not a valid recommendation.

## System Settings >> Security and Privacy

First, go to `Privacy & Security` to see if there's a message about blocking the downloaded application with `Open Anyway `option. This is the easiest way to fix it.

By clicking `Open Anyway`, macOS will ask again if you want to open the file and, if you answer yes, it will ask for the user password and open it. 

## xattr command line tool

`xattr`handles extended attributes, which are additional metadata attached to files and directories beyond standard information like name or size. This tool is built into macOS natively. With `xattr` you can remove the `com.apple.quarantine` attribute from any file downloaded from Internet and the task is quite simple.

- `xattr` without arguments displays extended attributes:

```
> sudo xattr /Applications/My-app.app
> com.apple.quarantine
```

- `xattr -cr` removes all extended attributes:

`> sudo xattr -cr /Applications/My-app.app`

- After this command, `xattr` no longer displays `com.apple.quarantine` extended attribute:

```
> sudo xattr /Applications/My-app.app 
> (no output)
```

## Xattr-remove

SwiftUI application for macOS that removes `com.apple.quarantine` extended attribute from files downloaded from the Internet. Works by accepting files via drag and drop onto the app window. It has its own repo: [Xattr-remove](https://github.com/perez987/Xattr-remove).

This app is a simpler and lighter version of Xattr Editor. Instead of displaying and editing (removing, modifying, adding) extended attributes, it performs a single task: removing com.apple.quarantine in a quick way from files downloaded from the Internet so that they can be opened in macOS without Gatekeeper warnings.

## Xattr Editor

Xattr Editor is a simple GUI application to view/edit extended file attributes on macOS. This project is an expansion of Xattr-remove. It has their own [**repository**](https://github.com/perez987/Xattr-Editor).

## Result

Either way, System Settings, Xattr-remove, Xattr Editor or `xattr`, from this point on, the downloaded app will run without security prompts because the `com.apple.quarantine` attribute has been removed.
