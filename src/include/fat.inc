%ifndef FAT_INC
%define FAT_INC

; BPB sector offsets
%define bpb_bytes_per_logical_sector 0x00B
%define bpb_logical_sectors_per_cluster 0x00D
%define bpb_reserved_logical_sectors 0x00E
%define bpb_number_of_fats 0x010
%define bpb_root_directory_entries 0x011
%define bpb_total_logical_sectors 0x013
%define bpb_media_descripter 0x015
%define bpb_logical_sectors_per_fat 0x016
%define bpb_physical_sectors_per_track 0x018
%define bpb_number_of_heads 0x01A

%endif