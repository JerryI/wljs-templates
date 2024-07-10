BeginPackage["Notebook`Templates`", {
    "JerryI`Misc`Events`",
    "JerryI`Misc`Async`",
    "JerryI`Misc`Events`Promise`",
    "JerryI`Notebook`AppExtensions`",
    "JerryI`WLX`",
    "JerryI`WLX`Importer`",
    "JerryI`WLX`WebUI`",
    "Notebook`Editor`Snippets`"
}]


Begin["`Internal`"]

database = <||>;

$userLibraryPath = FileNameJoin[{Directory[], "UserTemplates"}];
$libraryPath = FileNameJoin[{$InputFileName // DirectoryName, "Library"}]

If[!FileExistsQ[ $userLibraryPath ], CreateDirectory[$userLibraryPath] ];

scan[filename_] := With[{name = FileBaseName[filename]},
    database[name] = filename
]

scan /@ Flatten[{FileNames["*.wln", $libraryPath, Infinity], FileNames["*.wln", $userLibraryPath, Infinity]}];

listener[OptionsPattern[] ] := 
With[{
    Controls = OptionValue["Controls"],
    Modals = OptionValue["Modals"],
    Path = If[DirectoryQ[#], #, DirectoryName[#] ] &@ OptionValue["Path"]
},
    EventHandler[EventClone[Controls], {"new_from_template" -> Function[Null, 
        With[{
            p = Promise[],
            cli = Global`$Client
        }, 
            EventFire[Modals, "Select", <|"Client"->cli, "Promise"->p, "Title"->"Which template", "Options"->Keys[database]|>];
            Then[p, Function[choise,
                With[{name = FileNameJoin[{Path, RandomWord[]<>".wln"}], template = Values[database][[choise["Result"] ]]},
                    CopyFile[template,  name];

                    With[{dir = FileNameJoin[{template // DirectoryName, "attachments"}], targetDir =  FileNameJoin[{name // DirectoryName, "attachments"}]},
                        If[FileExistsQ[dir],
                            If[!FileExistsQ[targetDir ], CreateDirectory[ targetDir ] ] ;
                            Map[Function[n, CopyFile[n, FileNameJoin[{targetDir, FileNameTake[n] }] ] ],  
                                FileNames["*.*", dir ]
                            ];
                        ]
                    ];

                    If[OptionValue["Path"] === Path,
                        WebUILocation[URLEncode[name], cli];
                    ,
                        WebUILocation[URLEncode[name], cli, "Target"->_];
                    ];
                ]
            ] ];
        ]        
    ]}];
    ""
]

Options[listener] = {"Path"->"", "Parameters"->"", "Modals"->"", "AppEvent"->"", "Controls"->"", "Messanger"->""}


AppExtensions`TemplateInjection["AppTopBar"] = listener;


SnippetsCreateItem[
    "newFileFromTemplate", 

    "Template"->ImportComponent["Ico.wlx"] , 
    "Title"->"New notebook from template"
];

(* just fwd *)
EventHandler[SnippetsEvents, {
    "newFileFromTemplate" -> Function[assoc, EventFire[assoc["Controls"], "new_from_template", True] ]
}];

End[]
EndPackage[]