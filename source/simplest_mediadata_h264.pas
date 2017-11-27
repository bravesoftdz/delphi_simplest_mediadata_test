(**
 * ��򵥵�����Ƶ���ݴ���ʾ��
 * Simplest MediaData Test
 *
 * ������ Lei Xiaohua
 * leixiaohua1020@126.com
 * �й���ý��ѧ/���ֵ��Ӽ���
 * Communication University of China / Digital TV Technology
 * http://blog.csdn.net/leixiaohua1020
 *
 * ����Ŀ�������¼�������Ƶ����ʾ����
 *  (1)�������ݴ�����򡣰���RGB��YUV���ظ�ʽ����ĺ�����
 *  (2)��Ƶ�������ݴ�����򡣰���PCM��Ƶ������ʽ����ĺ�����
 *  (3)H.264�����������򡣿��Է��벢����NALU��
 *  (4)AAC�����������򡣿��Է��벢����ADTS֡��
 *  (5)FLV��װ��ʽ�������򡣿��Խ�FLV�е�MP3��Ƶ�������������
 *  (6)UDP-RTPЭ��������򡣿��Խ�����UDP/RTP/MPEG-TS���ݰ���
 *
 * This project contains following samples to handling multimedia data:
 *  (1) Video pixel data handling program. It contains several examples to handle RGB and YUV data.
 *  (2) Audio sample data handling program. It contains several examples to handle PCM data.
 *  (3) H.264 stream analysis program. It can parse H.264 bitstream and analysis NALU of stream.
 *  (4) AAC stream analysis program. It can parse AAC bitstream and analysis ADTS frame of stream.
 *  (5) FLV format analysis program. It can analysis FLV file and extract MP3 audio stream.
 *  (6) UDP-RTP protocol analysis program. It can analysis UDP/RTP/MPEG-TS Packet.
 *
 * Translated to delphi by Zhao Yipeng
 *)

unit simplest_mediadata_h264;

interface

uses
  System.Classes;

type
  TNaluType = (
    NALU_TYPE_SLICE    = 1,
    NALU_TYPE_DPA      = 2,
    NALU_TYPE_DPB      = 3,
    NALU_TYPE_DPC      = 4,
    NALU_TYPE_IDR      = 5,
    NALU_TYPE_SEI      = 6,
    NALU_TYPE_SPS      = 7,
    NALU_TYPE_PPS      = 8,
    NALU_TYPE_AUD      = 9,
    NALU_TYPE_EOSEQ    = 10,
    NALU_TYPE_EOSTREAM = 11,
    NALU_TYPE_FILL     = 12
  );

  TNaluPriority = (
    NALU_PRIORITY_DISPOSABLE = 0,
    NALU_PRIRITY_LOW         = 1,
    NALU_PRIORITY_HIGH       = 2,
    NALU_PRIORITY_HIGHEST    = 3
  );

  PNALU = ^TNALU;
  TNALU = packed record
    startcodeprefix_len: Int32;      //! 4 for parameter sets and first slice in picture, 3 for everything else (suggested)
    len: UInt32;                     //! Length of the NAL unit (Excluding the start code, which does not belong to the NALU)
    max_size: UInt32;                //! Nal Unit Buffer size
    forbidden_bit: Int32;            //! should be always FALSE
    nal_reference_idc: Int32;        //! NALU_PRIORITY_xxxx
    nal_unit_type: Int32;            //! NALU_TYPE_xxxx
    buf: PByte;                    //! contains the first byte followed by the EBSP
  end;

function FindStartCode2(Buf: PByte): Integer;
function FindStartCode3(Buf: PByte): Integer;
function GetAnnexbNALU(nalu: PNALU): Integer;

var
  h264bitstream: TFileStream;
  info2: Integer = 0;
  info3: Integer = 0;
implementation

function FindStartCode2(Buf: PByte): Integer;
begin
  if (Buf[0] <> 0) or (Buf[1] <> 0) or (Buf[2] <> 1) then
    Result := 0 //0x000001?
  else
    Result := 1;
end;

function FindStartCode3(Buf: PByte): Integer;
begin
  if (Buf[0] <> 0) or (Buf[1] <> 0) or (Buf[2] <> 0) or (Buf[3] <> 1) then
    Result := 0 //0x00000001?
  else
    Result := 1;
end;

function GetAnnexbNALU(nalu: PNALU): Integer;
var
  pos: Integer;
  StartCodeFound, rewind: Integer;
  Buf: PByte;
begin
  pos := 0;
  GetMem(Buf, nalu.max_size);
  try
    nalu.startcodeprefix_len := 3;
    if 3 <> h264bitstream.Read(Buf[0], 3) then
    begin
      Exit(0);
    end;

    info2 := FindStartCode2 (Buf);
    if(info2 <> 1) then
    begin
      if(1 <> h264bitstream.Read(Buf[3], 1)) then
      begin
        Exit(0);
      end;
      info3 := FindStartCode3(Buf);
      if (info3 <> 1) then
      begin
        Exit(-1);
      end
      else
      begin
        pos := 4;
        nalu.startcodeprefix_len := 4;
      end;
    end
    else
    begin
      nalu.startcodeprefix_len := 3;
      pos := 3;
    end;
    StartCodeFound := 0;
    info2 := 0;
    info3 := 0;

  //    while (!StartCodeFound){
  //        if (feof (h264bitstream)){
  //            nalu->len = (pos-1)-nalu->startcodeprefix_len;
  //            memcpy (nalu->buf, &Buf[nalu->startcodeprefix_len], nalu->len);
  //            nalu->forbidden_bit = nalu->buf[0] & 0x80; //1 bit
  //            nalu->nal_reference_idc = nalu->buf[0] & 0x60; // 2 bit
  //            nalu->nal_unit_type = (nalu->buf[0]) & 0x1f;// 5 bit
  //            free(Buf);
  //            return pos-1;
  //        }
  //        Buf[pos++] = fgetc (h264bitstream);
  //        info3 = FindStartCode3(&Buf[pos-4]);
  //        if(info3 != 1)
  //            info2 = FindStartCode2(&Buf[pos-3]);
  //        StartCodeFound = (info2 == 1 || info3 == 1);
  //    }
  //
  //    // Here, we have found another start code (and read length of startcode bytes more than we should
  //    // have.  Hence, go back in the file
  //    rewind = (info3 == 1)? -4 : -3;
  //
  //    if (0 != fseek (h264bitstream, rewind, SEEK_CUR)){
  //        free(Buf);
  //        printf("GetAnnexbNALU: Cannot fseek in the bit stream file");
  //    }
  //
  //    // Here the Start code, the complete NALU, and the next start code is in the Buf.
  //    // The size of Buf is pos, pos+rewind are the number of bytes excluding the next
  //    // start code, and (pos+rewind)-startcodeprefix_len is the size of the NALU excluding the start code
  //
  //    nalu->len = (pos+rewind)-nalu->startcodeprefix_len;
  //    memcpy (nalu->buf, &Buf[nalu->startcodeprefix_len], nalu->len);//
  //    nalu->forbidden_bit = nalu->buf[0] & 0x80; //1 bit
  //    nalu->nal_reference_idc = nalu->buf[0] & 0x60; // 2 bit
  //    nalu->nal_unit_type = (nalu->buf[0]) & 0x1f;// 5 bit
  //    free(Buf);
  //
    finally
      FreeMem(Buf);
    end;
//    return (pos+rewind);
end;

end.
